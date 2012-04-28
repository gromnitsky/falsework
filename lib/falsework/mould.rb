require 'git'
require 'erb'
require 'digest/md5'
require 'securerandom'
require 'yaml'

require_relative 'cliutils'

module Falsework
  class MouldError < StandardError
    def initialize msg
      super msg
    end

    alias :orig_to_s :to_s
    def to_s
      "generator: #{orig_to_s}"
    end
  end

  # The directory with template may have files beginning with # char
  # which will be ignored in #project_seed (a method that creates a
  # shiny new project form a template).
  #
  # If you need to run through erb not only the contents of a file in a
  # template but it name itself, then use the following convention:
  #
  # %%VARIABLE%%
  #
  # which is equivalent of erb's: <%= VARIABLE %>. See 'ruby-cli'
  # template directory for examples.
  #
  # In the template files you may use any Mould instance variables. The
  # most usefull are:
  #
  # [@classy]       An original project name, for example, 'Foobar Pro'
  #
  # [@project]      A project name in lowercase, suitable for a name of an
  #                 executable, for example, 'Foobar Pro' would be
  #                 'foobar_pro'.
  #
  # [@camelcase]    A 'normalized' project name, for use in source code,
  #                 for example, 'foobar pro' would be 'FoobarPro'.
  #
  # [@user]         Github user name.
  # [@email]        User email.
  # [@gecos]        A full user name.
  class Mould
    # Where @user, @email & @gecos comes from.
    GITCONFIG = '~/.gitconfig'
    
    # The possible dirs for templates. The first one is system-wide.
    @template_dirs = [CliUtils::DIR_LIB_SRC.parent.parent + 'templates',
                      Pathname.new(Dir.home) + ".#{Meta::NAME}" + 'templates']
    class << self
      attr_reader :template_dirs
    end
    
    # The template used if user didn't select one.
    TEMPLATE_DEFAULT = 'ruby-cli'
    # A file name with configurations for the inject commands.
    TEMPLATE_CONFIG = '#config.yaml'
    # A list of files to ignore in any template.
    IGNORE_FILES = ['.gitignore']
    # Note file name
    NOTE = '.' + Meta::NAME

    # A directory of a new generated project.
    attr_reader :project
    # template configuration
    attr_reader :conf

    # [project] A name of the future project; may include all crap with spaces.
    # [template] A name of the template for the project.
    # [user] Github username; if nil we are extracting it from the ~/.gitconfig.
    # [email] Github email
    # [gecos] A full author name from ~/.gitconfig.
    def initialize(project, template, user = nil, email = nil, gecos = nil)
      @project = Mould.name_project project
      raise MouldError, "invalid project name '#{project}'" unless Mould.name_valid?(@project)
      @camelcase = Mould.name_camelcase project
      @classy = Mould.name_classy project
      
      @batch = false
      @template = template || TEMPLATE_DEFAULT
      @dir_t = Mould.templates[@template] || fail(MouldError, "template '#{@template}' not found")

      # default config
      @conf = {
        'exe' => [{
                    'src' => nil,
                    'dest' => 'bin/%s',
                    'mode_int' => 0744
                  }],
        'doc' => [{
                    'src' => nil,
                    'dest' => 'doc/%s.rdoc',
                    'mode_int' => nil
                  }],
        'test' => [{
                     'src' => nil,
                     'dir' => 'test/test_%s.rb',
                     'mode_int' => nil
                   }]
      }
      configParse
      
      gc = Git.global_config rescue gc = {}
      @user = user || gc['github.user']
      @email = email || ENV['GIT_AUTHOR_EMAIL'] || ENV['GIT_COMMITTER_EMAIL'] || gc['user.email']
      @gecos = gecos || ENV['GIT_AUTHOR_NAME'] || ENV['GIT_COMMITTER_NAME']  || gc['user.name']

      [['github.user', @user],
       ['user.email', @email],
       ['user.name', @gecos]].each {|i|
        fail MouldError, "missing #{i.first} in #{GITCONFIG}" if i.last.to_s == ''
      }
    end

    # Modifies an internal list of available template directories
    def self.template_dirs_add(dirs)
      return unless defined? dirs.each

      dirs.each {|idx|
        fail "#{idx} is not a Pathname" unless idx.instance_of?(Pathname)
        
        if ! File.directory?(idx)
          CliUtils.warnx "invalid additional template directory: #{idx}"
        else
          @template_dirs << idx
        end
      }
    end
    
    # Hyper-fast generator of something like uuid suitable for code
    # identifiers. Return a string.
    def self.uuidgen_fake
      loop {
        r = ('%s_%s_%s_%s_%s' % [
                                 SecureRandom.hex(4),
                                 SecureRandom.hex(2),
                                 SecureRandom.hex(2),
                                 SecureRandom.hex(2),
                                 SecureRandom.hex(6),
                                ]).upcase
        return r if r[0] !~ /\d/
      }
    end
    
    # Return false if @t is invalid.
    def self.name_valid?(t)
      return false if !t || t[0] =~ /\d/
      t =~ /^[a-zA-Z0-9_]+$/ ? true : false
    end

    # Return cleaned version of an original project name, for example,
    # 'Foobar Pro'
    def self.name_classy(t)
      t ? t.gsub(/\s+/, ' ').strip : ''
    end

    # Return a project name in lowercase, suitable for a name of an
    # executable; for example, 'Foobar Pro' would be 'foobar_pro'.
    def self.name_project(raw)
      raw || (return '')

      r = raw.gsub(/[^a-zA-Z0-9_]+/, '_').downcase
      r.sub!(/^_/, '');
      r.sub!(/_$/, '');

      r
    end

    # Return a 'normalized' project name, for use in source code; for
    # example, 'foobar pro' would be 'FoobarPro'.
    def self.name_camelcase(raw)
      raw || (return '')
      raw.strip.split(/[^a-zA-Z0-9]+/).map{|idx|
        idx[0].upcase + idx[1..-1]
      }.join
    end
    
    # Return a hash {name => dir} with current possible template names
    # and corresponding directories.
    def self.templates
      r = {}
      @template_dirs.each {|i|
        Dir.glob(i + '*').each {|j|
          r[File.basename(j)] = Pathname.new(j) if File.directory?(j)
        }
      }
      r
    end

    # Generate a new project in @project directory from @template.
    #
    # Return false if nothing was extracted.
    def project_seed
      uuid = Mould.uuidgen_fake # useful variable for the template
      
      # check for existing project
      fail MouldError, "directory '#{@project}' is not empty" if Dir.glob(@project + '/*').size > 0

      Dir.mkdir @project unless File.directory?(@project)
      CliUtils.veputs 1, "Project path: #{File.expand_path(@project)}"

      r = false
      CliUtils.veputs 1, "Template: #{@dir_t}"
      symlinks = []
      Dir.chdir(@project) {
        Mould.traverse(@dir_t.to_s) {|idx|
          file = idx.sub(/^#{@dir_t}\//, '')
          next if IGNORE_FILES.index {|i| file.match(/#{i}$/) }

          if File.symlink?(idx)
            # we'll process them later on
            is_dir = File.directory?(@dir_t + '/' + File.readlink(idx))
            symlinks << [Mould.resolve_filename(File.readlink(idx), binding),
                         Mould.resolve_filename(file, binding)]
          elsif File.directory?(idx)
            CliUtils.veputs 1, "D: #{file}"
            Dir.mkdir Mould.resolve_filename(file, binding)
          else
            CliUtils.veputs 1, "N: #{file}"
            to = Mould.resolve_filename(file, binding)
            Mould.extract(idx, binding, to)
          end
          r = true
        }

        # create saved symlinks
        symlinks.each {|idx|
          src = idx[0]
          dest = idx[1]
          CliUtils.veputs 1, "L: #{dest} => #{src}"
          File.symlink(src, dest)
        }
      }
      
      r
    end

    # Parse a config. Return false on error.
    #
    # [rvars]  A list of variable names which must be in the config.
    def configParse rvars = []
      r = false

      file = @dir_t + TEMPLATE_CONFIG
      if File.readable?(file)
        begin
          myconf = YAML.load_file file
          myconf[:file] = file
          r = true
        rescue
          CliUtils.warnx "cannot parse #{file}: #{$!}"
          return false
        end
        rvars.each { |i|
          CliUtils.warnx "missing or nil '#{i}' in #{file}" if ! myconf.key?(i) || ! myconf[i]
          return false
        }

        if r
          # # resolve file names
          # ['obsolete', 'files'].each do |section|
          #   if myconf['upgrade'] && myconf['upgrade'][section]
          #     myconf['upgrade'][section].each_with_index {|f, idx|
          #       myconf['upgrade'][section][idx] = Mould.resolve_filename f, getBinding
          #     }
          #   end
          # end
          
          @conf.merge!(myconf)
        end
      end
      
      r
    end
    
    # Add a file from the template.
    #
    # [mode] Is either 'exe', 'doc' or 'test'.
    # [target] A test/doc/exe file to create.
    #
    # Return a list of a created files.
    #
    # Useful variables in the template:
    #
    # [target]
    # [target_camelcase]
    # [target_classy]
    # [uuid]
    def add(mode, target)
      target_orig = target
      target = Mould.name_project target_orig
      fail MouldError, "invalid target name '#{target_orig}'" if !Mould.name_valid? target
      target_camelcase = Mould.name_camelcase target_orig
      target_classy = Mould.name_classy target_orig
      uuid = Mould.uuidgen_fake
      
      created = []

      unless @conf[mode][0]['src']
        CliUtils.warnx "hash '#{mode}' is empty in #{@conf[:file]}"
        return []
      end

      @conf[mode].each {|idx|
        to = idx['dest'] % target

        begin
          Mould.extract @dir_t + idx['src'], binding, to
          File.chmod(idx['mode_int'], to) if idx['mode_int']
        rescue
          CliUtils.warnx "failed to create '#{to}' (check your #config.yaml): #{$!}"
        else
          created << to
        end
      }

      created
    end
    
    # Walk through a directory tree, executing a block for each file or
    # directory. Ignores _._, _.._ and files starting with _#_
    # character.
    #
    # [start] The directory to start with.
    def self.traverse(start, &block)
      l = Dir.glob(start + '/*', File::FNM_DOTMATCH).delete_if {|i|
        i.match(/\/?\.\.?$/) || i.match(/^#|\/#/)
      }
      # stop if directory is empty (contains only . and ..)
      return if l.size == 0
      
      l.sort.each {|i|
        yield i
        # recursion!
        self.traverse(i) {|j| block.call j} if File.directory?(i)
      }
    end
    
    # Extract file @from into @to.
    #
    # [binding] A binding for eval.
    def self.extract from, binding, to
      t = ERB.new File.read(from.to_s)
      t.filename = from.to_s # to report errors relative to this file
      begin
        output = t.result(binding)
        md5_system = Digest::MD5.hexdigest(output)
      rescue Exception
        fail MouldError, "bogus template file '#{from}': #{$!}"
      end

      if ! File.exists?(to)
        # write a skeleton
        begin
          File.open(to, 'w+') { |fp| fp.puts output }
          # transfer the exec bit to the generated result
          File.chmod(0744, to) if !defined?(FakeFS) && File.stat(from.to_s).executable?
        rescue
          fail MouldError, "cannot generate: #{$!}"
        end
      else
        # warn a careless user
        CliUtils.warnx "'#{to}' already exists" if md5_system != Digest::MD5.file(to).hexdigest
      end
    end

    # Resolve t from possible %%VARIABLE%% scheme.
    def self.resolve_filename t, binding
      t || (return '')
      
      re = /%%([^%]+)%%/
      t = ERB.new(t.gsub(re, '<%= \+ %>')).result(binding) if t =~ re
      t.sub(/\.#erb$/, '')
    end

    def getBinding
      binding
    end


    def noteCreate
      h = {
        'project' => {
          'classy' => @classy,
          'created' => DateTime.now.iso8601
        },
        Meta::NAME => {
          'version' => Meta::VERSION,
          'template' => @template
        }
      }

      file = @project +'/'+ NOTE
      File.open(file, 'w+') {|fp|
        CliUtils.veputs 1, "N: #{File.basename(file)}"
        fp.puts "# DO NOT DELETE THIS FILE"
        fp.puts "# unless you don't want to upgrade scaffolds in the future."
        fp.puts h.to_yaml
      }
    end
    
  end
end

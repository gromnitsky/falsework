require 'git'
require 'erb'
require 'digest/md5'
require 'securerandom'

require_relative 'trestle'

module Falsework
  # The directory with template may have files beginning with # char
  # which will be ignored in #project_seed (a method that creates a
  # shiny new project form a template).
  #
  # If you need to run through erb not only the contents of a file in a
  # template but it name itself, then use the following convention:
  #
  # %%VARIABLE%%
  #
  # which is equivalent of erb's: <%= VARIABLE %>. See 'ruby-naive'
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
    @@template_dirs = [Trestle.gem_libdir + '/templates',
                       File.expand_path('~/.' + Meta::NAME + '/templates')]
    # The template used if user didn't select one.
    TEMPLATE_DEFAULT = 'ruby-naive'
    # A file name with configurations for the inject commands.
    TEMPLATE_CONFIG = '#config.yaml'
    # A list of files to ignore in any template.
    IGNORE_FILES = ['.gitignore']

    # A verbose level for -v CLO.
    attr_accessor :verbose
    # -b CLO.
    attr_accessor :batch
    # A directory of a new generated project.
    attr_reader :project

    # [project] A name of the future project; may include all crap with spaces.
    # [template] A name of the template for the project.
    # [user] Github username; if nil we are extracting it from the ~/.gitconfig.
    # [email] Github email
    # [gecos] A full author name from ~/.gitconfig.
    def initialize(project, template, user = nil, email = nil, gecos = nil)
      @project = Mould.name_project project
      raise "invalid project name '#{project}'" if !Mould.name_valid? @project
      @camelcase = Mould.name_camelcase project
      @classy = Mould.name_classy project
      
      @verbose = false
      @batch = false
      @template = template
      @dir_t = Mould.templates[@template || TEMPLATE_DEFAULT] || Trestle.errx(1, "no such template: #{template}")

      # default config
      @conf = {
        exe: [{
                src: nil,
                dest: 'bin/%s',
                mode_int: 0744
              }],
        doc: [{
                src: nil,
                dest: 'doc/%s.rdoc',
                mode_int: nil
              }],
        test: [{
                 src: nil,
                 dir: 'test/test_%s.rb',
                 mode_int: nil
               }]
      }
      Mould.config_parse(@dir_t + '/' + TEMPLATE_CONFIG, [], @conf)
      
      gc = Git.global_config rescue gc = {}
      @user = user || gc['github.user']
      @email = email || ENV['GIT_AUTHOR_EMAIL'] || ENV['GIT_COMMITTER_EMAIL'] || gc['user.email']
      @gecos = gecos || ENV['GIT_AUTHOR_NAME'] || ENV['GIT_COMMITTER_NAME']  || gc['user.name']

      [['github.user', @user],
       ['user.email', @email],
       ['user.name', @gecos]].each {|i|
        Trestle.errx(1, "missing #{i.first} in #{GITCONFIG}") if i.last.to_s == ''
      }
    end

    # Modifies an internal list of available template directories
    def self.template_dirs_add(dirs)
      return unless defined? dirs.each

      dirs.each {|idx|
        if ! File.directory?(idx)
          Trestle.warnx "invalid additional template directory: #{idx}"
        else
          @@template_dirs << idx
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
      @@template_dirs.each {|i|
        Dir.glob(i + '/*').each {|j|
          r[File.basename(j)] = j if File.directory?(j)
        }
      }
      r
    end

    # Generate a new project in @project directory from @template.
    #
    # Return false if nothing was extracted.
    def project_seed()
      uuid = Mould.uuidgen_fake # useful variable for the template
      
      # check for existing project
      Trestle.errx(1, "directory '#{@project}' is not empty") if Dir.glob(@project + '/*').size > 0

      Dir.mkdir @project unless File.directory?(@project)
      puts "Project path: #{File.expand_path(@project)}" if @verbose

      r = false
      puts "Template: #{@dir_t}" if @verbose
      symlinks = []
      Dir.chdir(@project) {
        Mould.traverse(@dir_t) {|idx|
          file = idx.sub(/^#{@dir_t}\//, '')
          next if IGNORE_FILES.index {|i| file.match(/#{i}$/) }

          if File.symlink?(idx)
            # we'll process them later on
            is_dir = File.directory?(@dir_t + '/' + File.readlink(idx))
            symlinks << [Mould.get_filename(File.readlink(idx), binding),
                         Mould.get_filename(file, binding)]
          elsif File.directory?(idx)
            puts "D: #{file}"  if @verbose
            Dir.mkdir Mould.get_filename(file, binding)
          else
            puts "N: #{file}" if @verbose
            to = Mould.get_filename(file, binding)
            Mould.extract(idx, binding, to)
          end
          r = true
        }

        # create saved symlinks
        symlinks.each {|idx|
          src = idx[0]
          dest = idx[1]
          puts "L: #{dest} => #{src}" if @verbose
          File.symlink(src, dest)
        }
      }
      
      r
    end

    # Parse a config. Return false on error.
    #
    # [file] A file to parse.
    # [rvars] A list of variable names which must be in the config.
    # [hash] a hash to merge results with
    def self.config_parse(file, rvars, hash)
      r = true
      
      if File.readable?(file)
        begin
          myconf = YAML.load_file(file)
        rescue
          Trestle.warnx "cannot parse #{file}: #{$!}"
          return false
        end
        rvars.each { |i|
          Trestle.warnx "missing or nil '#{i}' in #{file}" if ! myconf.key?(i.to_sym) || ! myconf[i.to_sym]
          r = false
        }
        
        hash.merge!(myconf) if r && hash
      else
        r = false
      end
      
      r
    end
    
    # Add an executable or a test from the template.
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
      raise "invalid target name '#{target_orig}'" if !Mould.name_valid? target
      target_camelcase = Mould.name_camelcase target_orig
      target_classy = Mould.name_classy target_orig
      uuid = Mould.uuidgen_fake
      
      created = []

      return [] unless @conf[mode.to_sym][0][:src]

      @conf[mode.to_sym].each {|idx|
        to = idx[:dest] % target

        begin
          Mould.extract(@dir_t + '/' + idx[:src], binding, to)
          File.chmod(idx[:mode_int], to) if idx[:mode_int]
        rescue
          Trestle.warnx "failed to create '#{to}' (check your #config.yaml): #{$!}"
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
    def self.extract(from, binding, to)
      t = ERB.new(File.read(from))
      t.filename = from # to report errors relative to this file
      begin
        output = t.result(binding)
        md5_system = Digest::MD5.hexdigest(output)
      rescue Exception
        Trestle.errx(1, "bogus template file '#{from}': #{$!}")
      end

      if ! File.exists?(to)
        # write a skeleton
        begin
          File.open(to, 'w+') { |fp| fp.puts output }
          # transfer the exec bit to the generated result
          File.chmod(0744, to) if File.stat(from).executable?
        rescue
          Trestle.errx(1, "cannot generate: #{$!}")
        end
      elsif
        # warn a careless user
        if md5_system != Digest::MD5.file(to).hexdigest
          Trestle.errx(1, "'#{to}' already exists")
        end
      end
    end

    # Resolve @t from possible %%VARIABLE%% scheme.
    def self.get_filename(t, binding)
      t || (return '')
      
      re = /%%([^%]+)%%/
      t = ERB.new(t.gsub(re, '<%= \+ %>')).result(binding) if t =~ re
      t.sub(/\.#erb$/, '')
    end
    

    # Search for all files in the template directory the line
    #
    # /^..? :erb:/
    #
    # in first n lines. If the line is found, the file is considered a
    # candidate for an upgrade. Return a hash {target:template}
    def upgradable_files()
      line_max = 4
      r = {}
      Falsework::Mould.traverse(@dir_t) {|i|
        next if File.directory?(i)
        next if File.symlink?(i) # hm...

        File.open(i) {|fp|
          n = 0
          while n < line_max && line = fp.gets
            if line =~ /^..? :erb:/
              t = i.sub(/#{@dir_t}\//, '')
              r[Mould.get_filename(t, binding)] = i
              break
            end
            n += 1
          end
        }
      }
      
      r
    end

    # We can upgrade only those files, which were explicitly marked by
    # ':erb' sign a the top the file. They are collected by
    # upgradable_files() method.
    #
    # The upgrade can happened only if one following conditions is met:
    # 
    # 1. there is no such files (all or some of them) in the project at
    #    all;
    #
    # 2. the files are from the previous version of falsework.
    #
    # The situation may combine: you may have some missing and some old
    # files. But if there is at least 1 file from a newer version of
    # falsework then no upgrade is possible--it's considered a user
    # decision to intentionally have some files from the old versions of
    # falsework.
    #
    # Neithe we do check for a content of upgradable files nor try to
    # merge old with new. (Why?)
    def upgrade()
      # 0. search for 'new' files in the template
      uf = upgradable_files
      fail "template #{@template} cannot offer you files for the upgrade" if uf.size == 0
 #     pp uf
      
      # 1. analyse 'old' files
      u = {}
      uf.each {|k, v|
        if ! File.readable?(k)
          u[k] = v
        else
          # check for its version
          File.open(k) {|fp|
            is_versioned = false
            while line = fp.gets
              if line =~ /^# Don't remove this: falsework\/(#{Gem::Version::VERSION_PATTERN})\/(.+)\/.+/
                is_versioned = true
                if $3 != (@template || TEMPLATE_DEFAULT)
                  fail "file #{k} is from '#{$3}' template"
                end
                if Gem::Version.new(Meta::VERSION) >= Gem::Version.new($1)
#                  puts "#{k}: #{$1}"
                  u[k] = v
                  break
                else
                  fail "file #{k} is from a newer version of #{Meta::NAME}: " + $1
                end
              end
            end

            Trestle.warnx("#{k}: unversioned") if ! is_versioned
          }
        end
      }
      fail "template #{@template || TEMPLATE_DEFAULT} cannot find files for an upgrade" if u.size == 0

      # 2. ask user for a commitment
      if ! @batch
        puts "Here is a list of files in project #{@project} we can try to upgrade/add:\n\n"
        u.each {|k,v| puts "\t#{k}"}
        printf %{
Does this look fine? Type y/n and press enter. If you choose 'y', those files
will be replaced with newer versions. Your old files will be preserved with
an '.old' extension. So? }
        if STDIN.gets =~ /^y/i
          puts ""
        else
          puts "\nNo? See you later."
          exit 0
        end
      end

      # 3. rename & write new
      count = 1
      total = u.size
      tsl = total.to_s.size*2+1
      u.each {|k, v|
        printf("%#{tsl}s) mv %s %s\n",
               "#{count}/#{total}", k, "#{k}.old") if @verbose
        File.rename(k, "#{k}.old") rescue Trestle.warnx('renaming failed')
        printf("%#{tsl}s  Extracting %s ...\n", "", File.basename(v)) if @verbose
        FileUtils.mkdir_p(File.dirname(k))
        Mould.extract(v, binding, k)
        count += 1
      }
    end
    
  end # Mould
end

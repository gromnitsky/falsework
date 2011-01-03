require 'git'
require 'erb'
require 'digest/md5'

require_relative 'trestle'

# Class Mould heavily uses 'naive' template. Theoretically it can manage
# any template as long as it has files mentioned in #add.
#
# The directory with template may have files beginning with _#_ char
# which will be ignored in #project_seed (a method that creates a shiny
# new project form a template).
#
# If you need to run through erb not only the contents of a file in a
# template but it name itself, then use the following convention:
#
# %%VARIABLE%%
#
# which is equivalent of erb's: <%= VARIABLE %>. See naive template
# directory for examples.
#
# In the template files you may use any Mould instance variables. The
# most usefull are:
#
# [@project]  A project name.
# [@user]     Github user name.
# [@email]    User email.
# [@gecos]    A full user name.
module Falsework
  class Mould
    GITCONFIG = '~/.gitconfig'
    TEMPLATE_DIRS = [Trestle.gem_libdir + '/templates',
                     File.expand_path('~/.' + Meta::NAME + '/templates')]
    TEMPLATE_DEFAULT = 'naive'
    IGNORE_FILES = ['.gitignore']

    attr_accessor :verbose, :batch
    
    def initialize(project, user = nil, email = nil, gecos = nil)
      @verbose = false
      @batch = false
      
      gc = Git.global_config rescue gc = {}
      @project = project
      @user = user || gc['github.user']
      @email = email || ENV['GIT_AUTHOR_EMAIL'] || ENV['GIT_COMMITTER_EMAIL'] || gc['user.email']
      @gecos = gecos || ENV['GIT_AUTHOR_NAME'] || ENV['GIT_COMMITTER_NAME']  || gc['user.name']

      [['github.user', @user],
       ['user.email', @email],
       ['user.name', @gecos]].each {|i|
        Trestle.errx(1, "missing #{i.first} in #{GITCONFIG}") if i.last.to_s == ''
      }
    end

    # Return a hash {name => dir} with current possible template names
    # and corresponding directories.
    def self.templates
      r = {}
      TEMPLATE_DIRS.each {|i|
        Dir.glob(i + '/*').each {|j|
          r[File.basename(j)] = j if File.directory?(j)
        }
      }
      r
    end

    # Generate a new project in @project directory from _template_.
    #
    # [template] If it's nil TEMPLATE_DEFAULT will be used.
    # [filter]   A regexp for matching particular files in the
    #            template directory.
    #
    # Return false if nothing was extracted.
    def project_seed(template, filter)
      sl = ->(is_dir, *args) {
        is_dir ? Mould.erb_fname(*args) : Mould.erb_fname(*args).sub(/\.erb$/, '')
      }
      
      # check for existing project
      Trestle.errx(1, "directory '#{@project}' is not empty") if Dir.glob(@project + '/*').size > 0

      Dir.mkdir(@project) unless File.directory?(@project)
      prjdir = File.expand_path(@project)
      puts "Project path: #{prjdir}" if @verbose

      origdir = Dir.pwd;
      Dir.chdir @project

      r = false
      start = Mould.templates[template || TEMPLATE_DEFAULT] || Trestle.errx(1, "no such template: #{template}")
      puts "Template: #{start}" if @verbose
      symlinks = []
      Mould.traverse(start) {|i|
        file = i.sub(/^#{start}\//, '')
        next if filter ? file =~ filter : false
        next if IGNORE_FILES.index {|ign| file.match(/#{ign}$/) }

        if File.symlink?(i)
          # we'll process them later on
          is_dir = File.directory?(start + '/' + File.readlink(i))
          symlinks << [sl.call(is_dir, File.readlink(i), binding),
                       sl.call(is_dir, file, binding)]
        elsif File.directory?(i)
          puts("D: #{file}") if @verbose
          file = Mould.erb_fname(file, binding)
#          FileUtils.mkdir_p(prjdir + '/' + file)
          Dir.mkdir(prjdir + '/' + file)
          Dir.chdir(prjdir + '/' + file)
        else
          puts("N: #{file}") if @verbose
          to = File.basename(Mould.erb_fname(file, binding), '.erb')
          Mould.extract(start + '/' + file, binding, to)
          # make files in bin/ executable
          File.chmod(0744, to) if file =~ /bin\//
        end
        r = true
      }

      # create saved symlinks
      Dir.chdir prjdir
      symlinks.each {|i|
#        src = i[0].sub(/#{File.extname(i[0])}$/, '')
#        dest = i[1].sub(/#{File.extname(i[1])}$/, '')
        src = i[0]
        dest = i[1]
        puts "L: #{dest} => #{src}" if @verbose
        File.symlink(src, dest)
      }
      Dir.chdir origdir
      r
    end

    # Add an executable or a test from the _template_.
    #
    # [mode] Is either 'exe' or 'test'.
    # [what] A test/exe file to create.
    #
    # Return a name of a created file.
    def add(template, mode, what)
      start = Mould.templates[template || TEMPLATE_DEFAULT] || Trestle.errx(1, "no such template: #{template}")
      r = []

      case mode
      when 'exe'
        # script
        f = {}
        f[:from] = start + '/' + 'bin/%%@project%%.erb'
        f[:exe] = true
        f[:to] = "bin/#{what}"
        r << f

        # doc (reading an 'ignored' file from the template)
        f = {}
        f[:from] = start + '/' + 'doc/#util.rdoc.erb'
        f[:exe] = false
        f[:to] = "doc/#{what}.rdoc"
        r << f
      when 'test'
        f = {}
        f[:from] = start + '/' + 'test/test_%%@project%%.rb.erb'
        f[:exe] = false
        f[:to] = "#{mode}/test_#{what}.rb"
        r << f
      else
        fail "invalid mode #{mode}"
      end

      r.each {|i|
        Mould.extract(i[:from], binding, i[:to])
        File.chmod(0744, i[:to]) if i[:exe]
      }
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
    
    # Extract into the current directory 1 file from _path_.
    #
    # [bin] A binding for eval.
    # [to]  If != nil write to a particular, not guessed file name.
    def self.extract(path, bin, to = nil)
      t = ERB.new(File.read(path))
      t.filename = path # to report errors relative to this file
      begin
#        pp t.result
        md5_system = Digest::MD5.hexdigest(t.result(bin))
      rescue Exception
        Trestle.errx(1, "cannot read the template file: #{$!}")
      end

      skeleton = to || File.basename(path, '.erb')
      if ! File.exists?(skeleton)
        # write a skeleton
        begin
          File.open(skeleton, 'w+') { |fp| fp.puts t.result(bin) }
        rescue
          Trestle.errx(1, "cannot write the skeleton: #{$!}")
        end
      elsif
        # warn a careless user
        if md5_system != Digest::MD5.file(skeleton).hexdigest
          Trestle.errx(1, "#{skeleton} already exists")
        end
      end
    end

    def self.erb_fname(t, bin)
      re = /%%([^.]+)?%%/
      return ERB.new(t.gsub(re, '<%= \1 %>')).result(bin) if t =~ re
      return t
    end
    

    # Search for all files in the _template_ for the line
    #
    # /^..? :erb:/
    #
    # in first n lines. If the line is found, the file is considered a
    # candidate for an upgrade. Return a hash {target:template}
    def upgradable_files(template)
      line_max = 4
      r = {}
      Falsework::Mould.traverse(template) {|i|
        next if File.directory?(i)
        next if File.symlink?(i) # hm...

        File.open(i) {|fp|
          n = 0
          while n < line_max && line = fp.gets
            if line =~ /^..? :erb:/
              t = i.sub(/#{template}\//, '')
              r[Mould.erb_fname(t, binding).sub(/\.erb$/, '')] = i
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
    def upgrade(template)
      # 0. search for 'new' files in the template
      t = Mould.templates[template || TEMPLATE_DEFAULT] || Trestle.errx(1, "no such template: #{template}")
      uf = upgradable_files(t)
      fail "template #{template} cannot offer to you files for an upgrade" if uf.size == 0
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
              if line =~ /^# Don't remove this: falsework\/(#{Gem::Version::VERSION_PATTERN})\/(\w+)\/.+/
                is_versioned = true
                if $3 != (template || TEMPLATE_DEFAULT)
                  fail "file #{k} is from #{$3} template"
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
      fail "template #{template || TEMPLATE_DEFAULT} cannot find files for an upgrade" if u.size == 0

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

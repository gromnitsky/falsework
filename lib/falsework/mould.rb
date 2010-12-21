require 'git'
require 'erb'
require 'digest/md5'

require_relative 'utils'

module Falsework
  class Mould
    GITCONFIG = '~/.gitconfig'
    TEMPLATE_DIRS = [Utils.gem_libdir + '/templates',
                     File.expand_path('~/.' + Meta::NAME + '/templates')]
    TEMPLATE_DEFAULT = 'naive'
    IGNORE_FILES = ['.gitignore']

    attr_accessor :verbose
    
    def initialize(project, user = nil, email = nil, gecos = nil)
      @verbose = false
      
      gc = Git.global_config rescue gc = {}
      @project = project
      @user = user || gc['github.user']
      @email = email || ENV['GIT_AUTHOR_EMAIL'] || ENV['GIT_COMMITTER_EMAIL'] || gc['user.email']
      @gecos = gecos || ENV['GIT_AUTHOR_NAME'] || ENV['GIT_COMMITTER_NAME']  || gc['user.name']

      [['github.user', @user],
       ['user.email', @email],
       ['user.name', @gecos]].each {|i|
        Utils.errx(1, "missing #{i.first} in #{GITCONFIG}") if i.last.to_s == ''
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
        is_dir ? Mould.erb_dirname(*args) : Mould.erb_filename(*args)
      }
      
      # check for existing project
      Utils.errx(1, "directory '#{@project}' is not empty") if Dir.glob(@project + '/*').size > 0

      Dir.mkdir(@project) unless File.directory?(@project)
      prjdir = File.expand_path(@project)
      puts "Project path: #{prjdir}" if @verbose

      origdir = Dir.pwd;
      Dir.chdir @project

      r = false
      start = Mould.templates[template || TEMPLATE_DEFAULT] || Utils.errx(1, "no such template: #{template}")
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
          file = Mould.erb_dirname(file, binding)
#          FileUtils.mkdir_p(prjdir + '/' + file)
          Dir.mkdir(prjdir + '/' + file)
          Dir.chdir(prjdir + '/' + file)
        else
          puts("N: #{file}") if @verbose
          to = File.basename(Mould.erb_filename(file, binding), '.erb')
          Mould.extract(start + '/' + file, binding, to)
          # make files in bin/ executable
          File.chmod(0744, to) if file =~ /bin\//
        end
        r = true
      }

      # create saved symlinks
      Dir.chdir prjdir
      symlinks.each {|i|
        src = i[0].sub(/#{File.extname(i[0])}$/, '')
        dest = i[1].sub(/#{File.extname(i[1])}$/, '')
        puts "L: #{dest} => #{src}" if @verbose
        File.symlink(src, dest)
      }
      Dir.chdir origdir
      r
    end

    # Create an executable or a test from the _template_.
    #
    # [mode] Is either 'exe' or 'test'.
    # [what] A test/exe file to create.
    #
    # Return a name of a created file.
    def create(template, mode, what)
      start = Mould.templates[template || TEMPLATE_DEFAULT] || Utils.errx(1, "no such template: #{template}")

      t = case mode
          when 'exe'
            to = ["bin/#{what}", true]
            start + '/' + 'bin/.@project..erb'
          when 'test'
            to = ["#{mode}/test_#{what}.rb", false]
            start + '/' + 'test/test_utils.rb.erb'
          else
            fail "invalid mode #{mode}"
          end
      Mould.extract(t, binding, to[0])
      File.chmod(0744, to[0]) if to[1]
      return to[0]
    end
    
    # Walk through a directory tree, executing a block for each file or
    # directory.
    #
    # [start] The directory to start with.
    def self.traverse(start, &block)
      l = Dir.glob(start + '/{*}', File::FNM_DOTMATCH)
      # stop if directory is empty (contains only . and ..)
      return if l.size <= 2
      
      l[2..-1].each {|i|
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
        Utils.errx(1, "cannot read the template file: #{$!}")
      end

      skeleton = to || File.basename(path, '.erb')
      if ! File.exists?(skeleton)
        # write a skeleton
        begin
          File.open(skeleton, 'w+') { |fp| fp.puts t.result(bin) }
        rescue
          Utils.errx(1, "cannot write the skeleton: #{$!}")
        end
      elsif
        # warn a careless user
        if md5_system != Digest::MD5.file(skeleton).hexdigest
          Utils.errx(1, "#{skeleton} already exists")
        end
      end
    end

    # Evaluate _t_ as a special directory name.
    #
    # [bin] A binding for eval.
    def self.erb_dirname(t, bin)
      if t =~ /^(.+\/)?\.(.+)\.$/
        return ERB.new("#{$1}<%= #{$2} %>").result(bin)
      end
      return t
    end

    # Evaluate _t_ as a special file name.
    #
    # [bin] A binding for eval.
    def self.erb_filename(t, bin)
      if t =~ /^(.+\/)?\.(.+)\.(\..+)?.erb$/
        return ERB.new("#{$1}<%= #{$2} %>#{$3}").result(bin)
      end
      return t
    end
    
  end # Mould
end

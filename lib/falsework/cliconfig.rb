# :erb: ruby-cli

require 'pathname'
require 'yaml'
require 'optparse'
require 'shellwords'

require_relative 'cliutils'

module Falsework

  # Load configuration from 3 places (starting from least significant):
  # config file, env variable, command line.
  class CliConfig
    # Possible config file locations.
    DIR_CONFIG = [Pathname.new(Dir.home) + ".#{Meta::NAME}",
                  Pathname.new('/etc'),
                  Pathname.new('/usr/etc'),
                  Pathname.new('/usr/local/etc'),
                  CliUtils.gem_dir_lib.parent.parent + 'etc']

    # Example:
    #
    # conf = CliConfig.new
    # conf[:my_option] = 123
    # conf.load
    def initialize
      @conf = Hash.new
      @conf[:verbose] = 0
      @conf[:banner] = "Usage: #{File.basename($0)} [options]"
      @conf[:config_name] = Meta::NAME + '.yaml'
      @conf[:config_env] = Meta::NAME.upcase + '_CONF'
      @conf[:config_dirs] = DIR_CONFIG
    end

    # Setter for @conf
    def []=(key, val)
      CliUtils.verbose = val if key == :verbose # sync verbosity levels
      @conf[key] = val
    end

    # Getter for @conf
    def [](key)
      @conf[key]
    end

    # Return a full path to a config file or nil if no config file found.
    def getConfigPath
      if @conf[:config_name].index('/')
        return @conf[:config_name] if File.file?(@conf[:config_name])
      else 
        @conf[:config_dirs].each {|i|
          r = Pathname.new(i) + @conf[:config_name]
          return r if File.file?(r)
        }
      end

      CliUtils.warnx "no config file '#{@conf[:config_name]}' found" if @conf[:verbose] >= 2
      return nil
    end

    # Load a config from file. Return true on success or false otherwise.
    def loadFile
      file = getConfigPath
      return false unless file

      CliUtils::veputs(2, "Loading #{File.basename(file)}... " + CliUtils::NNL_MARK)
      myconf = YAML.load_file(file) rescue CliUtils.errx(1, "cannot parse config #{file}: #{$!}")
      # preserve existing values
      @conf.merge!(myconf) {|key, oldval, newval| oldval }
      CliUtils::veputs(2, "OK")
      return true
    end

    # Check if options in array opts are in @conf.
    def requiredOptions?(opts)
      opts.each {|idx|
        if !@conf.key?(idx.to_sym) || !@conf[idx.to_sym]
          CliUtils.errx(1, "option #{idx} is either nil or missing")
        end
      }
    end

    # Parse CLO and env variable. If block is given it is passed with
    # OptionParser object as a parameter.
    def optParse
      o = OptionParser.new do |o|
        o.banner = @conf[:banner]
        o.banner = @conf[:banner]
        o.on('-v', 'Be more verbose.') { |i|
          self[:verbose] += 1
        }
        o.on('-V', '--version', 'Show version & exit.') { |i|
          puts Meta::VERSION
          exit 0
        }
        o.on('--config NAME',
             "Set a config name or file",
             "(default is #{@conf[:config_name]}).") {|arg|
          @conf[:config_name] = arg
        }
        o.on('--config-dirs', 'Show possible config locations.') {
          mark = false
          @conf[:config_dirs].each { |idx|
            f = Pathname(idx) + @conf[:config_name]
            if File.file?(f) && !mark
              puts "* #{f}"
              mark = true
            else
              puts "  #{f}"
            end
          }
          exit 0
        }

        yield o if block_given?

        env = nil
        env = ENV[@conf[:config_env]].shellsplit if ENV.key?(@conf[:config_env])
        [env, ARGV].each { |i| o.parse!(i) if i }
      end
    end

    # Parse CLO, env variables and load config file.
    #
    # [reqOpts] an array of requied options
    # [&block]  a optional block for OptionParser
    def load(reqOpts = [], &block)
      optParse &block
      loadFile
      requiredOptions?(reqOpts)
    end
    
  end
end

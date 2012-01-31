# :erb: ruby-cli

require 'pp'
require 'open4'
require 'pathname'

require_relative 'meta'

module Falsework
  
  # Common routines useful in any CLI program.
  class CliUtils
    # Physical location of program libraries.
    DIR_LIB_SRC = Pathname.new File.dirname(__FILE__)
    # veputs uses this to decide to put a newline or not to put.
    NNL_MARK = '__NNL__'

    # Class-wide verbosity level.
    @@verbose = 0

    # Setter.
    def self.verbose=(val)
      @@verbose = val
    end

    # Getter.
    def self.getVerbose
      @@verbose
    end

    # A handy check. Use it like:
    #
    # puts (CliUtils.debug ? "DEBUG mode" : "")
    def self.debug
      @@verbose >= 2
    end

    # A handy method that return a nicely formatted current global
    # backtrace.
    def self.getBacktrace
      "#{$!}\n\nBacktrace:\n\n#{$!.backtrace.join("\n")}"
    end

    # Print an error msg & exit if exit_code > 0.
    def self.errx(exit_code = 0, msg)
      $stderr.puts File.basename($0) + ' error: ' + msg.to_s
      exit exit_code if exit_code > 0
    end

    # Print a warning.
    def self.warnx(msg)
      $stderr.puts File.basename($0) + ' warning: ' + msg.to_s
    end

    # [level] Verbosity level.
    # [msg]   A message to print.
    #
    # Don't print msg with a newline if it contains NNL_MARK at the end.
    def self.veputs(level, msg)
      t = msg.dup
      
      nnl = false
      if t.match(/#{NNL_MARK}$/)
        t.sub!(/#{$&}/, '')
        nnl = true
      end

      if @@verbose >= level
        nnl ? print(t) : print("#{t}\n")
        $stdout.flush
      end
    end

    # Analogue to a shell command +which+.
    def self.which(file)
      return true if file =~ %r%\A/% and File.exist? file
      
      ENV['PATH'].split(File::PATH_SEPARATOR).any? do |path|
        File.exist? File.join(path, file)
      end
    end
    
    # Execute cmd and return an array [exit_status, stderr, stdout].
    def self.exec(cmd)
      so = sr = ''
      status = Open4::popen4(cmd) { |pid, stdin, stdout, stderr|
        so = stdout.read
        sr = stderr.read
      }
      [status.exitstatus, sr, so]
    end
  end

end

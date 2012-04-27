require 'yaml'

require_relative 'mould'
require_relative 'utils'

module Falsework
  
  class UpgradeError < StandardError
    def initialize msg
      super msg
    end

    alias :orig_to_s :to_s
    def to_s
      "upgrade: #{orig_to_s}"
    end
  end

  class Upgrader
    NOTE = '.' + Meta::NAME

    def self.noteLoad file = NOTE
      r = YAML.load_file(file) rescue fail(UpgradeError, $!)
      
      fail UpgradeError, 'no project name' unless Utils.all_set?(r['project']['classy'])
      fail UpgradeError, "no #{Meta::NAME} version" unless Utils.all_set?(r[Meta::NAME]['version'])
      r[Meta::NAME]['version'] = Gem::Version.new r[Meta::NAME]['version']
      fail UpgradeError, "no #{Meta::NAME} template" unless Utils.all_set?(r[Meta::NAME]['template'])

      unless Mould.templates[r[Meta::NAME]['template']]
        fail UpgradeError, "unknown template '#{r[Meta::NAME]['template']}'"
      end

      r
    end

    def initialize dir, note = NOTE
      fail UpgradeError, "directory #{dir} is unreadable" unless dir && File.readable?(dir)
      @dir = Pathname.new dir
      @note = Upgrader.noteLoad(@dir + note)

      @mould = Mould.new dir, @note[Meta::NAME]['template']
      @template_dir = Pathname.new(Mould.templates[@note[Meta::NAME]['template']])
      @project = @mould.project

      @batch = false
    end

    attr_accessor :batch
    attr_reader :project
    attr_reader :template_dir

    def getProjectBinding
      @mould.getBinding
    end

    def able?
      return false unless @mould.conf['upgrade']
      return false if Gem::Version.new(@mould.conf['upgrade']['from']) > @note[Meta::NAME]['version']
      return false unless @mould.conf['upgrade']['files'].is_a?(Array) && @mould.conf['upgrade']['files'].size > 0
      true
    end

    def files
      @mould.conf['upgrade']['files']
    end

    def obsolete
      @mould.conf['upgrade']['obsolete']
    end

    # Return true if user enter 'y' or 'a', false otherwise.
    # Always return true for non-batch mode.
    def userSaidYes msg, file
      return true if @batch
      
      print "#{msg} '#{file}'? [y/n/a] "
      asnwer = $stdin.gets
      
      if asnwer =~ /^a/i
        @batch = true
        return true
      end
      
      yes = (asnwer =~ /^y/i)
      return true if yes

      false
    end
    
    def obsolete_rm
      obsolete.each {|idx|
        next unless userSaidYes 'rm', idx
        FileUtils.rm_rf idx
      }
    end

    def upgrade save_old = false # yield f
      fail UpgradeError, "this project cannot be upgraded" unless able?

      files.each {|idx|
        f = Mould.get_filename idx, @mould.getBinding

        next unless userSaidYes 'update', f
        
        FileUtils.mv f, f + '.orig' if save_old
        Mould.extract @template_dir + idx, @mould.getBinding, f

        # say 'opa-popa was updated'
        yield f if block_given?
      }
    end
    
  end
end

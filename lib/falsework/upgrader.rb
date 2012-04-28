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
    def self.noteLoad file = Mould::NOTE
      r = YAML.load_file(file) rescue raise

      ['project', 'template'].each {|idx|
        fail "no #{idx} spec" unless r[idx]
      }
      
      fail 'no project name' unless Utils.all_set?(r['project']['classy'])
      fail "no template version" unless Utils.all_set?(r['template']['version'])
      r['template']['version'] = Gem::Version.new r['template']['version']
      fail "no template name" unless Utils.all_set?(r['template']['name'])

      unless Mould.templates[r['template']['name']]
        fail "unknown template '#{r['template']['name']}'"
      end

      r
    end

    def initialize dir, note = Mould::NOTE
      fail UpgradeError, "directory #{dir} is unreadable" unless File.readable?(dir.to_s)
      @dir = Pathname.new File.realpath(dir)

      begin
        @note = Upgrader.noteLoad(@dir + note)
      rescue
        raise UpgradeError, $!
      end

      @mould = Mould.new @note['project']['classy'], @note['template']['name']
      @template_dir = Mould.templates[@note['template']['name']]
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
      return false if Gem::Version.new(@mould.conf['upgrade']['from']) > @note['template']['version']
      return false unless @mould.conf['upgrade']['files'].is_a?(Array) && @mould.conf['upgrade']['files'].size > 0
      true
    end

    def files
      @mould.conf['upgrade']['files']
    end

    def obsolete
      @mould.conf['upgrade']['obsolete'] || []
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
    
    def upgrade save_old = false # yield f
      fail UpgradeError, "this project cannot be upgraded" unless able?

      at_least_one = false
      files.each {|idx|
        f = Mould.resolve_filename idx, @mould.getBinding

        next unless userSaidYes 'update', f
        
        FileUtils.mv f, f + '.orig' if save_old && File.exist?(f)
        Mould.extract @template_dir + idx, @mould.getBinding, f

        # say 'opa-popa was updated'
        yield f if block_given?
        at_least_one = true
      }

      # update a note file
      @mould.noteCreate true if at_least_one
    end
    
  end
end

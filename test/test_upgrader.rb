require 'fakefs/safe'

require_relative 'helper'
require_relative '../lib/falsework/upgrader'

class TestUpgrader < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  # def test_note
  #   rm_rf 'templates/foo'
  #   r = CliUtils.exec "#{@cmd} new templates/foo"
  #   assert_equal 0, r[0]
    
  #   Dir.chdir('templates/foo') {
      
  #   }
  # end

  def test_load_note
    assert Upgrader.noteLoad('example/note/full')
  end

  def test_upgradable
    e = assert_raises(UpgradeError) { Upgrader.new '/DOES/NOT/EXIST' }
    assert_match /directory .+ is unreadable/, e.message

    e = assert_raises(UpgradeError) { Upgrader.new 'templates' }
    assert_match /No such file or directory - .+\.#{Meta::NAME}/, e.message
    
    e = assert_raises(UpgradeError) { Upgrader.new nil, nil }
    assert_match /directory  is unreadable/, e.message
    
    e = assert_raises(UpgradeError) { Upgrader.new 'example/note', 'template-unknown' }
    assert_match /unknown template/, e.message

    u = Upgrader.new 'example/note', 'project-too-old'
    refute u.able?
    
    u = Upgrader.new 'example/note', 'full'
    assert u.able?
  end

  def test_files
    u = Upgrader.new 'example/note', 'full'
    assert_operator u.files.size, :>, 1
    assert_operator u.obsolete.size, :>=, 1
  end

  def test_upgrade_fail
    u = Upgrader.new 'example/note', 'project-too-old'
    e = assert_raises(UpgradeError) { u.upgrade }
    assert_match /this project cannot be upgraded/, e.message
  end
    
  def test_upgrade
    u = Upgrader.new 'example/note', 'full'
    u.batch = true
    temp = {}
    u.files.each {|idx|
      f = u.template_dir + idx
      temp[f] = File.read f
    }
    
    ClearFakeFS do
      # copy some template files into fakefs
      temp.each {|key, val|
        FileUtils.mkdir_p File.dirname(key)
        File.open(key, 'w+') {|fp| fp.write val}
      }

      # make a skeleton
      checksum_old = []
      u.files.each {|idx|
        f = Mould.resolve_filename(idx, u.getProjectBinding)
        FileUtils.mkdir_p File.dirname(f)
        FileUtils.touch f
        checksum_old << Digest::MD5.file(f)
      }

      u.upgrade true

      checksum_new = []
      u.files.each {|idx|
        f = Mould.resolve_filename(idx, u.getProjectBinding)
        assert File.readable?(f + '.orig')
        checksum_new << Digest::MD5.file(f)
      }

      refute_equal checksum_old, checksum_new
    end
  end

end

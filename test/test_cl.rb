require_relative 'helper'
require_relative '../lib/falsework/mould'

class TestFalsework_3867654745 < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  def test_listdirs
    assert_equal 2, Mould.class_variable_get(:@@template_dirs).size
    out, err = capture_io { Mould.template_dirs_add ["DOESN'T EXISI"] }
    assert_equal 2, Mould.class_variable_get(:@@template_dirs).size
    Mould.template_dirs_add [Dir.pwd]
    assert_equal 3, Mould.class_variable_get(:@@template_dirs).size
    
    assert_equal true, Mould.templates.key?("templates")
  end

  def test_new_dir_from_config
    r = Trestle.cmd_run "#{@cmd} --config /NO_SUCH_FILE.yaml listdirs"
    assert_equal(0, r[0])
    assert_equal(2, r[2].split("\n").size)
    
    r = Trestle.cmd_run "#{@cmd} --config templates/config-01.yaml listdirs"
    assert_equal(0, r[0])
    assert_equal(3, r[2].split("\n").size)
  end
end

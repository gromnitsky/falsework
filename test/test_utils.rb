require_relative 'helper'

class TestFalsework < MiniTest::Unit::TestCase
  CMD = cmd('falsework') # get path to the exe & cd to tests directory
  
  def setup
    # this runs every time before test_*
  end

  def test_project_list
    r = cmd_run "#{CMD} list"
    assert_equal(0, r[0])
    assert_match(/naive\n/, r[2])
  end

  def test_project_new
    rm_rf 'templates/foo'
    r = cmd_run "#{CMD} new templates/foo -v"
#    pp r
    assert_equal(0, r[0], r)

    # check for first & last lines only
    out = r[2].split("\n")
    assert_match(/^Project path: \//, out.first)
    assert_equal("L: README.rdoc => doc/README.rdoc", out.last)

    # add files
    origdir = pwd
    cd 'templates/foo'

    r = cmd_run "../../#{CMD} exe qqq"
    assert_equal(0, r[0])
    assert_equal(true, File.executable?('bin/qqq'))

    r = cmd_run "../../#{CMD} test qqq"
    assert_equal(0, r[0])
    assert_equal(true, File.exist?('test/test_qqq.rb'))
    
    cd origdir
  end

  def test_project_invalid_name
    r = cmd_run "#{CMD} new 123"
    assert_equal(1, r[0])
    assert_match(/project name cannot start with a digit/, r[1])
  end
end

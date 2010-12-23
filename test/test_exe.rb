require_relative 'helper'

class TestFalsework < MiniTest::Unit::TestCase
  CMD = cmd('falsework') # get path to the exe & cd to tests directory
  
  def setup
    # this runs every time before test_*
  end

  def test_project_list
    r = Trestle.cmd_run "#{CMD} list"
    assert_equal(0, r[0])
    assert_match(/naive\n/, r[2])
  end

  def test_project_new
    rm_rf 'templates/foo'
    r = Trestle.cmd_run "#{CMD} new templates/foo -v"
#    pp r
    assert_equal(0, r[0], r)

    out = r[2].split("\n")
    assert_match(/^Project path: \//, out[0])
    assert_equal("L: README.rdoc => doc/README.rdoc", out[-2])
    assert_match(/Creating a git repository in .+... OK/, out[-1])

    tree = ["templates/foo/.git",
            "templates/foo/.gitignore",
            "templates/foo/README.rdoc",
            "templates/foo/Rakefile",
            "templates/foo/bin",
            "templates/foo/bin/foo",
            "templates/foo/doc",
            "templates/foo/doc/LICENSE",
            "templates/foo/doc/NEWS.rdoc",
            "templates/foo/doc/README.rdoc",
            "templates/foo/etc",
            "templates/foo/etc/foo.yaml",
            "templates/foo/lib",
            "templates/foo/lib/foo",
            "templates/foo/lib/foo/meta.rb",
            "templates/foo/lib/foo/trestle.rb",
            "templates/foo/test",
            "templates/foo/test/helper.rb",
            "templates/foo/test/helper_trestle.rb",
            "templates/foo/test/rake_git.rb",
            "templates/foo/test/test_foo.rb"]

    assert_equal(tree,
                 Dir.glob('templates/foo/**/*', File::FNM_DOTMATCH).sort.delete_if {|i|
                   i.match(/\.\.?$/) || i.match(/\.git[^i]/)
                 })

    # add files
    origdir = pwd
    cd 'templates/foo'

    r = Trestle.cmd_run "../../#{CMD} exe qqq"
    assert_equal(0, r[0])
    assert_equal(true, File.executable?('bin/qqq'))

    r = Trestle.cmd_run "../../#{CMD} test qqq"
    assert_equal(0, r[0])
    assert_equal(true, File.exist?('test/test_qqq.rb'))
    
    cd origdir
  end

  def test_project_invalid_name
    r = Trestle.cmd_run "#{CMD} new 123"
    assert_equal(1, r[0])
    assert_match(/project name cannot start with a digit/, r[1])
  end
end

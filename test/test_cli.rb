require_relative 'helper'

# Heavy & slow.
class TestCommandLine < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  def test_project_ruby_cli
    rm_rf 'templates/foo'
    r = CliUtils.exec "#{@cmd} -v new templates/foo"
#    pp r
    assert_equal(0, r[0], r)

    out = r[2].split("\n")
    assert_match(/^Project path: \//, out[0])
    assert_equal "N: .falsework", out[-2]
    assert_match(/Creating a git repository in .+... OK/, out[-1])

    tree = ["templates/foo/.falsework",
            "templates/foo/.git",
            "templates/foo/.gitignore",
            "templates/foo/Gemfile",
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
            "templates/foo/foo.gemspec",
            "templates/foo/lib",
            "templates/foo/lib/foo",
            "templates/foo/lib/foo/cliconfig.rb",
            "templates/foo/lib/foo/cliutils.rb",
            "templates/foo/lib/foo/meta.rb",
            "templates/foo/test",
            "templates/foo/test/helper.rb",
            "templates/foo/test/helper_cliutils.rb",
            "templates/foo/test/test_foo.rb"]

    assert_equal(tree,
                 Dir.glob('templates/foo/**/*', File::FNM_DOTMATCH).sort.delete_if {|i|
                   i.match(/\.\.?$/) || i.match(/\.git[^i]/)
                 })

    Dir.chdir('templates/foo') {
      # check rake
      r = CliUtils.exec "rake -T"
      assert_equal 0, r[0]
      
      # add files
      r = CliUtils.exec "#{@cmd} exe qqq"
      assert_equal(0, r[0])
      assert_equal(true, File.executable?('bin/qqq'))
      # smoke test of generated exe
      r = CliUtils.exec "bin/qqq --version"
      assert_equal 0, r[0]
      assert_equal "0.0.1\n", r[2]

      r = CliUtils.exec "#{@cmd} test qqq"
      assert_equal(0, r[0])
      assert_equal(true, File.exist?('test/test_qqq.rb'))

      # upgrade
      r = CliUtils.exec "#{@cmd} upgrade -b"
#      pp r
      assert_equal 0, r[0]
      rm ['test/helper_cliutils.rb']
      
      r = CliUtils.exec "#{@cmd} upgrade -b"
      assert_equal 0, r[0]
      
      File.open('test/helper_cliutils.rb', 'w+') {|fp| fp.puts 'garbage' }
      r = CliUtils.exec "#{@cmd} upgrade -b --save"
      assert_equal 0, r[0]

      mv 'test', 'ttt'
      r = CliUtils.exec "#{@cmd} upgrade -b"
      assert_equal 0, r[0]

      # upgrade info
      r = CliUtils.exec "#{@cmd} upgrade check"
      assert_equal 0, r[0]
      
      r = CliUtils.exec "#{@cmd} upgrade list"
      assert_equal 0, r[0]
      assert_operator 1, :<=, r[2].split("\n").size

      r = CliUtils.exec "#{@cmd} upgrade list obsolete"
      assert_equal 0, r[0]
      assert_operator 1, :<=, r[2].split("\n").size
    }
  end

  def test_project_invalid_name
    r = CliUtils.exec "#{@cmd} new 123"
    assert_equal(EX_SOFTWARE, r[0])
    assert_match(/invalid project name/, r[1])
  end

  def test_project_c_glib
    rm_rf 'templates/c_glib'
    r = CliUtils.exec "#{@cmd} -t c-glib new templates/c-glib --no-git"
    assert_equal(0, r[0])

    Dir.chdir('templates/c_glib') {
      r = CliUtils.exec "#{@cmd} -t c-glib exe q-q-q"
      assert_equal(0, r[0])
      assert_equal(true, File.exist?('src/q_q_q.h'))
      assert_equal(true, File.exist?('src/q_q_q.c'))

      r = CliUtils.exec "#{@cmd} -t c-glib test q-q-q"
      assert_equal(0, r[0])
      assert_equal(true, File.exist?('test/test_q_q_q.c'))
      
      Dir.chdir('src') {
        r = CliUtils.exec "gmake"
        assert_equal 0, r[0]
        assert_equal true, File.executable?('c_glib')
        assert_equal(true, File.exist?('q_q_q.o'))
      }
      Dir.chdir('test') {
        r = CliUtils.exec "gmake"
        assert_equal 0, r[0]
        assert_equal true, File.executable?('test_utils')
        assert_equal true, File.executable?('test_q_q_q')

        r = CliUtils.exec "gmake test"
        assert_equal 0, r[0]
      }
    }
  end

  def test_new_dir_from_config
    r = CliUtils.exec "#{@cmd} --config /NO_SUCH_FILE.yaml list dirs"
    assert_equal(0, r[0])
    assert_equal(2, r[2].split("\n").size)
    
    r = CliUtils.exec "#{@cmd} --config templates/config-01.yaml list dirs"
    assert_equal(0, r[0])
    assert_equal(3, r[2].split("\n").size)
  end

  def test_project_list
    r = CliUtils.exec "#{@cmd} list"
    assert_equal(0, r[0])
    assert_match(/ruby-cli/, r[2])
  end

end

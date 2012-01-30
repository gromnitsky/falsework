require_relative 'helper'

class TestFalsework < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  def test_project_list
    r = CliUtils.exec "#{@cmd} list"
    assert_equal(0, r[0])
    assert_match(/ruby-cli/, r[2])
  end

  # very silly analogue of "sed -i'' -E 's/foo/bar/g' file"
  def sed(file, re, repl)
    o = File.read(file).gsub(re, repl)
    File.open(file, 'w+') {|fp| fp.printf(o) }
  end
  
  def test_project_ruby_cli
    rm_rf 'templates/foo'
    r = CliUtils.exec "#{@cmd} new templates/foo -v"
#    pp r
    assert_equal(0, r[0], r)

    out = r[2].split("\n")
    assert_match(/^Project path: \//, out[0])
    assert_equal("L: README.rdoc => doc/README.rdoc", out[-2])
    assert_match(/Creating a git repository in .+... OK/, out[-1])

    tree = ["templates/foo/.git",
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
            "templates/foo/lib",
            "templates/foo/lib/foo",
            "templates/foo/lib/foo/cliconfig.rb",
            "templates/foo/lib/foo/cliutils.rb",
            "templates/foo/lib/foo/meta.rb",
            "templates/foo/test",
            "templates/foo/test/helper.rb",
            "templates/foo/test/helper_cliutils.rb",
            "templates/foo/test/rake_git.rb",
            "templates/foo/test/test_foo.rb"]

    assert_equal(tree,
                 Dir.glob('templates/foo/**/*', File::FNM_DOTMATCH).sort.delete_if {|i|
                   i.match(/\.\.?$/) || i.match(/\.git[^i]/)
                 })

    Dir.chdir('templates/foo') {
      # add files
      r = CliUtils.exec "#{@cmd} exe qqq"
      assert_equal(0, r[0])
      assert_equal(true, File.executable?('bin/qqq'))
      assert_equal(true, File.exist?('doc/qqq.rdoc'))
      # smoke test of generated exe
      r = CliUtils.exec "bin/qqq --version"
      assert_equal 0, r[0]
      assert_equal "0.0.1\n", r[2]

      r = CliUtils.exec "#{@cmd} test qqq"
      assert_equal(0, r[0])
      assert_equal(true, File.exist?('test/test_qqq.rb'))

      # upgrade
      r = CliUtils.exec "#{@cmd} upgrade -b"
      assert_equal(0, r[0])
      rm ['test/helper_cliutils.rb', 'test/rake_git.rb']
      r = CliUtils.exec "#{@cmd} upgrade -b"
      assert_equal(0, r[0])
      sed 'test/helper_cliutils.rb',
      /^(# Don't.+falsework\/)\d+\.\d+\.\d+(\/.+)$/, '\1999.999.999\2'
      r = CliUtils.exec "#{@cmd} upgrade -b"
      assert_equal(1, r[0])
      assert_match(/file .+ is from .+ falsework: 999.999.999/, r[1])
      mv('test', 'ttt')
      r = CliUtils.exec "#{@cmd} upgrade -b"
      assert_equal(0, r[0])
    }
  end

  def test_project_invalid_name
    r = CliUtils.exec "#{@cmd} new 123"
    assert_equal(1, r[0])
    assert_match(/invalid project name/, r[1])
  end

  def test_project_c_glib
    rm_rf 'templates/c_glib'
    r = CliUtils.exec "#{@cmd} new templates/c-glib -t c-glib --no-git"
    assert_equal(0, r[0])

    Dir.chdir('templates/c_glib') {
      r = CliUtils.exec "#{@cmd} -t c-glib exe q-q-q"
      assert_equal(0, r[0])
      assert_equal(true, File.exist?('src/q_q_q.h'))
      assert_equal(true, File.exist?('src/q_q_q.c'))
      assert_equal(true, File.exist?('doc/q_q_q.1.asciidoc'))

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
end

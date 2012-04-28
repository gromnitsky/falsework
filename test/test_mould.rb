require 'fakefs/safe'

require_relative 'helper'
require_relative '../lib/falsework/mould'

class TestMould < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  def test_configParse
    ClearFakeFS do
      FileUtils.mkdir_p 't/ruby-cli'
      Mould.template_dirs.unshift Pathname.new('t')

      # no template config file
      m = Mould.new 'foo', nil
      refute m.conf[:upgrade]

      # invalid template config file
      File.open('t/ruby-cli/'+Mould::TEMPLATE_CONFIG, 'w+') {|fp|
        fp.puts 'garbage'
      }
      out, err = capture_io { m = Mould.new 'foo', nil }
      assert_match /cannot parse/, err

      Mould.template_dirs.shift
    end

    m = Mould.new 'foo', nil
    assert_equal 'lib/%%@project%%/cliconfig.rb', m.conf['upgrade']['files'].first
  end

  def test_name_project
    assert_equal '', Mould.name_project('')
    assert_equal '', Mould.name_project(nil)
    assert_equal '', Mould.name_project("\n")
    assert_equal 'foobar_pro', Mould.name_project('FooBar Pro')
    assert_equal 'foobar_pro', Mould.name_project("  FooBar --Pro?\n\n\n")
    assert_equal 'foobar_pro', Mould.name_project('foobar#pro,')
  end

  def test_name_classy
    assert_equal '', Mould.name_classy('')
    assert_equal '', Mould.name_classy(nil)
    assert_equal '', Mould.name_classy("\n")
    assert_equal 'FooBar Pro', Mould.name_classy('FooBar Pro')
    assert_equal 'FooBar Pro', Mould.name_classy("FooBar \n   Pro  ")
  end

  def test_name_valid
    assert_equal false, Mould.name_valid?('')
    assert_equal false, Mould.name_valid?(nil)
    assert_equal false, Mould.name_valid?("\n")
    assert_equal false, Mould.name_valid?('0foobar')
    assert_equal false, Mould.name_valid?('foobar ')
    assert_equal true, Mould.name_valid?('foobar')
  end
  
  def test_name_camelcase
    assert_equal '', Mould.name_camelcase('')
    assert_equal '', Mould.name_camelcase(nil)
    assert_equal '', Mould.name_camelcase("\n")
    assert_equal 'FP', Mould.name_camelcase('f p')
    assert_equal 'Foobar', Mould.name_camelcase('foobar')
    assert_equal 'FooBarPro', Mould.name_camelcase('FooBar Pro')
    assert_equal 'FooBarPro', Mould.name_camelcase("  FooBar --Pro?\n\n\n")
    assert_equal 'FoobarPro', Mould.name_camelcase('foobar#pro,')
  end

  def test_resolve_filename
    f = 'foo'
    b = 'bar'
    
    assert_equal '', Mould.resolve_filename(nil, binding)
    assert_equal '', Mould.resolve_filename('', binding)
    assert_equal 'f/b', Mould.resolve_filename('f/b', binding)
    assert_equal 'f/bar/q.txt', Mould.resolve_filename('f/%%b%%/q.txt', binding)
    assert_equal 'foo/bar/q.txt', Mould.resolve_filename('%%f%%/%%b%%/q.txt', binding)
  end

  def test_uuid
    512.times {|i|
      t = Mould.uuidgen_fake
      assert_match(/^[A-Z0-9]{8}_[A-Z0-9]{4}_[A-Z0-9]{4}_[A-Z0-9]{4}_[A-Z0-9]{12}$/, t)
      refute_match /\d/, t[0]
    }
  end

  def test_listdirs
    assert_equal 2, Mould.template_dirs.size
    out, err = capture_io { Mould.template_dirs_add [Pathname.new("DOESN'T EXISI")] }
    assert_equal 2, Mould.template_dirs.size
    
    assert_raises(RuntimeError) { Mould.template_dirs_add([Dir.pwd]) }
    assert_equal 2, Mould.template_dirs.size
    
    Mould.template_dirs_add [Pathname.new(Dir.pwd)]
    assert_equal 3, Mould.template_dirs.size

    assert_equal true, Mould.templates.key?("templates")
  end

end

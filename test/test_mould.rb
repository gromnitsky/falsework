require_relative 'helper'
require_relative '../lib/falsework/mould'

class TestFalsework_3673712978 < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  def test_config_parse
    refute Mould.config_parse "DOESN'T EXIST", nil, nil

    o = {}
    r = Mould.config_parse File.dirname(@cmd) + '/../etc/falsework.yaml', [], o
    assert_equal true, r

    o = { foo: 1 }
    r = Mould.config_parse File.dirname(@cmd) + '/../etc/falsework.yaml', ['bar'], o
    refute r
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

  def test_get_filename
    f = 'foo'
    b = 'bar'
    
    assert_equal '', Mould.get_filename(nil, binding)
    assert_equal '', Mould.get_filename('', binding)
    assert_equal 'f/b', Mould.get_filename('f/b', binding)
    assert_equal 'f/bar/q.txt', Mould.get_filename('f/%%b%%/q.txt', binding)
    assert_equal 'foo/bar/q.txt', Mould.get_filename('%%f%%/%%b%%/q.txt', binding)
  end
end

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
end

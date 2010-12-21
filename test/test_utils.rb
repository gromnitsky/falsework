require_relative 'helper'

class TestUtils < MiniTest::Unit::TestCase
  def setup
    cmd 'dummy' # cd to tests directory
  end

  def test_foobar
    fail "\u0430\u0439\u043D\u0435\u043D\u0435".encode(Encoding.default_external)
  end
end

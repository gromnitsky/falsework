require_relative 'helper'

class Test<%= rand 2**32 %> < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('<%= @project %>') # get path to the exe & cd to tests directory
  end

  def test_foobar
    flunk
  end
end

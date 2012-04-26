require_relative 'helper'
require_relative '../lib/falsework/upgrader'

class TestUpgrader < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*
    @cmd = cmd('falsework') # get path to the exe & cd to tests directory
  end

  def test_note
  end
end

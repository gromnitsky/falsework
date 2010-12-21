# Various staff for minitest.

require 'fileutils'
require 'open4'

include FileUtils

require_relative '../lib/falsework/utils'
include Falsework

# don't run tests automatically if they were invoked as 'gem check -t ...'
if $0 =~ /gem/
  require 'minitest/unit'
else
  require 'minitest/autorun'
end

# Return the right directory for (probably executable) _c_.
def cmd(c)
  case File.basename(Dir.pwd)
  when Meta::NAME.downcase
    # test probably is executed from the Rakefile
    Dir.chdir('test')
  when 'test'
    # we are in the test directory, there is nothing special to do
  else
    # tests were invoked by 'gem check -t falsework'
    begin
      Dir.chdir(Utils.gem_libdir + '/../../test')
    rescue
      raise "running tests from '#{Dir.pwd}' isn't supported: #{$!}"
    end
  end

  '../bin/' + c
end

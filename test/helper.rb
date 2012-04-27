require_relative 'helper_cliutils'

def ClearFakeFS
  return ::FakeFS unless block_given?
  ::FakeFS.activate!
  
  yield

ensure
  ::FakeFS.deactivate!
  ::FakeFS::FileSystem.clear
end

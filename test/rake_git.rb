#!/usr/bin/env ruby
# -*-ruby-*-
# :erb:

require 'git'
require 'pp'

# Return a list of files in a git repository _repdir_
def git_ls(repdir, ignore_some = true)
  ignore = ['/?\.gitignore$']

  r = []
  g = Git.open repdir
  g.ls_files.each {|i, v|
    next if ignore_some && ignore.index {|ign| i.match(/#{ign}/) }
    r << i
  }
  r
end

pp git_ls('.') if __FILE__ == $0

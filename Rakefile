# -*-ruby-*-

require 'rake/clean'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'

require 'yaml'
require_relative 'lib/falsework/mould'

def src2template target, prerequisite
  src = File.read prerequisite
  src.gsub! /#{Meta::NAME}/, '<%= @project %>'
  src.gsub! /#{Mould.name_camelcase(Meta::NAME)}/, '<%= @camelcase %>'

  File.open(target, 'w+') {|fp| fp.puts src }
  puts "Created: #{target}"
end

# Create a dynamic target list
def dynTargets
  YAML.load_file 'dynamic.yaml'
end

DYNAMICS = dynTargets

desc "Generate some dynamic template files"
task :dynamic do
  DYNAMICS.each {|key, val|
    src2template key, val
  }
end

# add rubi-cli dynamic files to a clobber target
CLOBBER.concat DYNAMICS.keys

require 'bundler/gem_tasks'

task default: [:test]

RDoc::Task.new('html') do |i|
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['doc/*', 'lib/**/*.rb']
  i.rdoc_files.exclude 'lib/**/templates/**/*'
end

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end

task test: [:dynamic]
task build: [:dynamic]

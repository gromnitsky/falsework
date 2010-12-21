# -*-ruby-*-

require 'erb'
require 'rake'
require 'rake/gempackagetask'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'

NAME = 'falsework'
require_relative "lib/#{NAME}/meta"

spec = Gem::Specification.new {|i|
  i.name = NAME
  i.version = `bin/#{i.name} -V`
  i.summary = "A primitive scaffold generator for CLI programs in Ruby."
  i.author = 'Alexander Gromnitsky'
  i.email = 'alexander.gromnitsky@gmail.com'
  i.homepage = "http://github.com/gromnitsky/#{i.name}"
  i.platform = Gem::Platform::RUBY
  i.required_ruby_version = '>= 1.9.2'
  i.files = FileList['lib/**/*', 'bin/*', 'doc/*',
                     'etc/*', '[A-Z]*', 'test/**/*']

  i.executables = FileList['bin/*'].gsub(/^bin\//, '')
  i.default_executable = i.name
  
  i.test_files = FileList['test/test_*.rb']
  
  i.rdoc_options << '-m' << 'doc/README.rdoc'
  i.extra_rdoc_files = FileList['doc/*']

  i.add_dependency('git', '>=  1.2.5')
  i.add_dependency('open4', '>= 1.0.1')
}

Rake::GemPackageTask.new(spec).define

task default: [:naive, :repackage]

Rake::RDocTask.new('doc') do |i|
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['doc/*', 'lib/**/*.rb']
  i.rdoc_files.exclude("lib/**/templates")
end

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end


ERB_TEMPLATE_UTILS = "lib/#{NAME}/utils.rb"
ERB_TARGET_UTILS = "lib/#{NAME}/templates/naive/lib/.@project./#{File.basename(ERB_TEMPLATE_UTILS)}.erb"
ERB_TEMPLATE_TEST_HELPER = "test/helper.rb"
ERB_TARGET_TEST_HELPER = "lib/#{NAME}/templates/naive/test/#{File.basename(ERB_TEMPLATE_TEST_HELPER)}.erb"

desc "Generate some erb targets for naive template"
task :naive => [ERB_TARGET_UTILS, ERB_TARGET_TEST_HELPER]

def make_erb(target, template)
  raw = File.read(template)
  raw.gsub!(/#{NAME}/, '<%= @project %>')
  raw.gsub!(/#{NAME.capitalize}/, '<%= @project.capitalize %>')

  mark = <<-EOF

# Don't remove this: <%= DateTime.now %> <%= #{NAME.capitalize}::Meta::NAME %> <%= #{NAME.capitalize}::Meta::VERSION %>
  EOF
  File.open(target, 'w+') {
    |fp| fp.puts raw + ERB.new(mark).result(binding)
  }
end

file ERB_TARGET_UTILS => [ERB_TEMPLATE_UTILS] do |t|
  make_erb(t.name, t.prerequisites[0])
end
file ERB_TARGET_TEST_HELPER => [ERB_TEMPLATE_TEST_HELPER] do |t|
  make_erb(t.name, t.prerequisites[0])
end

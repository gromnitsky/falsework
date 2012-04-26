#!/usr/bin/env ruby
# -*-ruby-*-

require_relative '../lib/falsework/mould'
include Falsework

# Search for all files in the project (except .git directory) for the line
#
# /^..? :erb: [^ ]+/
#
# in first 4 lines. If the line is found, the file is considered a
# skeleton for a template. Return a hash {target:template}
def erb_skeletons template
  line_max = 4
  target = Mould.template_dirs.first + template
  r = {}
  skiplist = ['/.git[^i]?', "templates", '/html', '/pkg',
              '/test/templates', 'rake_erb_templates.rb']

  Mould.traverse('.') {|i|
    next if File.directory?(i)
    next if File.symlink?(i)
    if skiplist.index {|ign| i.match(/\/?#{ign}\/?/) }
     next
    end
    
    File.open(i) {|fp|
      n = 0
      while n < line_max && line = fp.gets
        if line =~ /^..? :erb: [^\s]+/
          t = i.sub(/^.+?\//, '')
          r[target.to_s + '/' + t.sub(/#{Meta::NAME}/, '%%@project%%')] = t
          break
        end
        n += 1
      end
    }
  }
  
  r
end

def erb_make template, target, tmplt
  raw = File.read(tmplt)
  raw.gsub!(/#{Meta::NAME}/, '<%= @project %>')
  raw.gsub!(/#{Mould.name_camelcase(Meta::NAME)}/, '<%= @camelcase %>')

  mark = <<-EOF

# Don't remove this: <%= #{Mould.name_camelcase(Meta::NAME)}::Meta::NAME %>/<%= #{Meta::NAME.capitalize}::Meta::VERSION %>/#{template}/<%= DateTime.now %>
  EOF
  File.open(target, 'w+') {
    |fp| fp.puts raw + ERB.new(mark).result(binding)
  }
end


pp erb_skeletons 'ruby-cli' if __FILE__ == $0

module <%= @camelcase %>
  module Meta
    NAME = '<%= @project %>'
    VERSION = '0.0.1'
    AUTHOR = '<%= @gecos %>'
    EMAIL = '<%= @email %>'
    HOMEPAGE = 'http://github.com/<%= @user %>/' + NAME
  end
end

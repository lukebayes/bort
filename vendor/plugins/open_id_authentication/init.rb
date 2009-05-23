begin
  gem 'ruby-openid', '>= 2.1.6'
  require 'openid'
rescue LoadError
  puts "Install the ruby-openid gem (>= 2.1.6) to enable OpenID support"
end

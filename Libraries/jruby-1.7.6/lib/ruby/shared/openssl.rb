unless defined? JRUBY_VERSION
  warn 'Loading jruby-openssl in a non-JRuby interpreter'
end

# Load bouncy-castle gem if available
begin
  require 'bouncy-castle-java'
rescue LoadError
  # runs under restricted mode or uses builtin BC
end

# Load extension
require 'jruby'
# only boot ext if jar has not been loaded before
if require 'jopenssl.jar'
  org.jruby.ext.openssl.OSSLLibrary.new.load(JRuby.runtime, false)
end

if RUBY_VERSION >= '1.9.0'
  load('jopenssl19/openssl.rb')
else
  load('jopenssl18/openssl.rb')
end

require 'openssl/pkcs12'

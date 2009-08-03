begin
  require 'rubygems'
rescue LoadError
end

require "sinatra"
  
# Demo app built for 0.9.x
require "#{File.dirname(__FILE__)}/lib/app"

set :run, false
set :environment, :production
run Sinatra::Application


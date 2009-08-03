begin
  require 'rubygems'
rescue LoadError
end

require "sinatra"
require "#{File.dirname(__FILE__)}/lib/app"

set :run, false
set :environment, :production
run Sinatra::Application


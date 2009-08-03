begin
  require "rubygems"
rescue LoadError
end

require "sinatra"

get "/" do
  "it works!"
end

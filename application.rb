class Application < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :server, :thin
  get '/' do
    erb :index
  end
end
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/sinatra-restclient-oauth.db")

class Provider
  include DataMapper::Resource
  
  has n, :access_tokens
  
  property :id,                   Serial
  property :title,                String
  property :consumer_key,         String
  property :consumer_secret,      String
  property :request_token_url,    String
  property :authorize_url,        String
  property :access_token_url,     String
  property :created_at,           DateTime
  property :updated_at,           DateTime
  
  validates_presence_of :title, :consumer_key, :consumer_secret
end

class AccessToken
  include DataMapper::Resource
  
  belongs_to :provider
  
  property :id,                   Serial
  property :oauth_token,          String
  property :oauth_token_secret,   String
  property :created_at,           DateTime
  property :updated_at,           DateTime
end

DataMapper.finalize
Provider.auto_upgrade!
AccessToken.auto_upgrade!

class Application < Sinatra::Base
  set :root, File.dirname(__FILE__)
  enable :sessions
  use Rack::Flash
  
  get '/' do
    @providers = Provider.all
    
    erb :providers
  end
  
  get '/providers/new' do
    erb :new_provider
  end
  
  post '/providers' do
    @provider = Provider.new(params[:provider])
    
    if @provider.save
      flash[:notice] = "Provider created successfully."
      redirect '/'
    else
      flash[:error] = "There was a problem saving the provider."
      erb :new_provider
    end
  end
  
  get '/authorize' do
    erb :authorize
  end
  
  get '/request' do
    
  end
end
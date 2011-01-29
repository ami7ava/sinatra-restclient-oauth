DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/sinatra-restclient-oauth.db")

class Provider
  include DataMapper::Resource
  
  has 1, :access_token
  
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

  def authorized?
    if access_token
      !(access_token.oauth_token.blank? && access_token.oauth_token_secret.blank?)
    end
  end
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
    
    haml :providers
  end
  
  get '/providers/new' do
    haml :new_provider
  end

  get '/providers/:id' do
    @provider = Provider.get(params[:id])
    
    haml :show_provider
  end
  
  post '/providers' do
    @provider = Provider.new(params[:provider])
    
    if @provider.save
      flash[:notice] = "Provider created successfully."
      redirect '/'
    else
      flash[:error] = "There was a problem saving the provider."
      haml :new_provider
    end
  end
  
  post '/providers/:id/authorize' do
    provider = Provider.get(params[:id])

    consumer = OAuth::Consumer.new(provider.consumer_key, provider.consumer_secret,
      :request_token_path => provider.request_token_url,
      :access_token_path => provider.access_token_url,
      :authorize_path => provider.authorize_url)
    
    callback_url = "http://sinatra-restclient-oauth.local:9292/providers/#{provider.id}/callback"
    request_token = consumer.get_request_token(:oauth_callback => callback_url)
    session[:request_token] = request_token
    redirect request_token.authorize_url(:oauth_callback => callback_url)
  end
  
  get '/providers/:id/callback' do
    provider = Provider.get(params[:id])
    request_token = session[:request_token]
    access_token = request_token.get_access_token
    "#{access_token.token}--#{access_token.secret}"

    provider.access_token = AccessToken.new(
      :oauth_token => access_token.token,
      :oauth_token_secret => access_token.secret)
    
    if provider.save
      flash[:notice] = "Hooray! #{provider.title} is authorized now."
      redirect "/providers/#{provider.id}/console"
    end
  end

  get '/providers/:id/console' do
    @provider = Provider.get(params[:id])

    consumer = OAuth::Consumer.new(@provider.consumer_key, @provider.consumer_secret)
    access_token = @provider.access_token
    session[:access_token] = OAuth::AccessToken.new(consumer, 
      access_token.oauth_token, access_token.oauth_token_secret)
    haml :console
  end
end
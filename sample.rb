require 'rubygems'
require 'sinatra'
require 'json'
require 'vmc/client'
require 'rack-flash'

enable :sessions
use Rack::Flash

configure do
  @@target = "api.cloudfoundry.com"
end

before do

  # Example of how to only allow https
  unless (ENV['bypass_ssl'] && request.secure?)
    halt 401, 'This website can only be accessed over SSL'
  end

  @title = "Developers"
  @canonical_url = request.url
  @fb_app_id = ENV['facebook_app_id']

  if (session[:auth_token] && !session[:email])
    @vmcclient = VMC::Client.new(@@target, session[:auth_token])
    begin
      if (info = @vmcclient.info)
        session[:email] = info['user']
      end
    rescue
      session.delete :auth_token
    end
  end
end

post '/login' do
  email = params[:email]
  password = params[:password]

  if (email && password)
    @vmcclient = VMC::Client.new(@@target)
    begin
      @vmcclient.login(email, password)
      session[:auth_token] = @vmcclient.auth_token
      session[:email] = email
    rescue Exception => ex
      flash[:error] =  "Login Failed"
    end
  else
    flash[:error] = "Fill out the form"
  end
  redirect '/'
end

get '/logout' do
  session.delete :auth_token
  session.delete :email
  redirect '/'
end

get '/' do
  haml :index

end



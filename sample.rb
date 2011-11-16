require 'rubygems'
require 'sinatra'
require 'json'
require 'vmc/client'
require 'rack-flash'

require_relative 'lib/app'
require_relative 'lib/cf_mongoid'
require_relative 'lib/cf_builder'

include CloudFoundry

enable :sessions
use Rack::Flash

configure do
  @@target = "api.cloudfoundry.com"
  CloudFoundry::Mongo.config
end

before do

  # Example of how to only allow https
  #unless (ENV['bypass_ssl'] && request.secure?)
  #  halt 401, 'This website can only be accessed over SSL'
  #end

  @title = "Gallery"
  @canonical_url = request.url
  @fb_app_id = ENV['facebook_app_id']

  if (session[:auth_token] && @vmcclient.nil? )
    @vmcclient = VMC::Client.new(@@target, session[:auth_token])
    puts "Created new session for auth_token"
    unless session[:email]
      begin
        if (info = @vmcclient.info)
          session[:email] = info['user']
        end
      rescue
        session.delete :auth_token
      end
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
  #TODO: Get from mongo db
  @links = {}
  @links['Ruby'] = {:display_name => "Ruby Box.net", :url => "/apps/boxnet-ruby"}
  @links['Spring'] = {:display_name => "Spring Box.net", :url => "/apps/boxnet-spring"}

  haml :index

end

post '/apps/:app_name/new_copy' do |app_name|
  @app_name = app_name
  build_app if app_name ==  "boxnet-ruby"
end

get '/apps/:app_name/new_copy' do |app_name|
  @app_name = app_name
  build_app if app_name ==  "boxnet-ruby"
end

def build_app
  # Find the app if its browsable
  @app = App.new
  @app.display_name = "Box.net Ruby Sample"
  @app.app_urls = ["box-rebuilt.cloudfoundry.com"]
  @title = @app.display_name
  @app.description = "A starter Box.net application which showcases accessing files and folders as well as sharing."
  @thumb_url = "http://veederline.com.au/wp-content/uploads/2011/07/digital_pub_box_net.jpg"
  @app.app_type = 'sinatra'
  # Avatar, name, description

  # GitHub Location
  @app.git_repo =  "https://github.com/seanrose/box-rebuilt"
  @commit = "3e26a2f"

  parts =  @app.app_urls.first.split('.')
  @new_name = parts[0] + rand(9999).to_i.to_s

  if session[:email]
    a,b = session[:email].split '@'
    @new_name = parts[0] + "-#{@commit}-" + a
  end
  #services

  #env vars
  @env_vars = {}
  @env_vars['BOX_API_KEY'] = "enter your key here"

  haml :new_copy
end

post '/apps/:app_name/do_copy' do |app_name|
  @app_name = app_name
  clone_app if app_name ==  "boxnet-ruby"
end


def clone_app
  if (session[:email] && params[:source_code] && params[:new_name] && params[:app_type] && params[:commit])
    #begin
      builder = CloudFoundry::Builder.new

      puts "params are #{params.inspect}"

      #THE magic
      commit = params[:commit] #the last commit for that repo on git
      repo_name = params[:source_code].gsub(/https\:\/\/github.com\//, '').gsub(/\//, "-")
      extracted_dir = "#{Dir.tmpdir}/#{repo_name}-#{commit}"

      puts "Extracted dir is #{extracted_dir}and repo #{repo_name}"

      unless (Dir.exists? extracted_dir)
        tmp_file = "#{Dir.tmpdir}raw-#{params[:new_namw]}.zip"
        zip_url = "#{params[:source_code]}/zipball/master"

        puts "Downloading and unzipping from #{zip_url}"
        builder.get_app(tmp_file, zip_url)
        #extracts to extracted_dir
        builder.unpack(tmp_file, Dir.tmpdir)
      end

      puts "Creating app from #{extracted_dir}"
      builder.create_app(@vmcclient, params[:new_name], params[:app_type], 'location' => extracted_dir, 'upload' => true)

      #TODO: Create/bind services once we have manifest

      env_array = []
      if (params[:env_vars])
        var_names = params[:env_vars].split(',')
        var_names.each do |var_name|
          env_array << "#{var_name}=#{params[var_name]}"
        end

        app_hash = @vmcclient.app_info(params[:new_name])
        app_hash[:env] = env_array


        begin
          @vmcclient.update_app(params[:new_name], app_hash)
        rescue Exception => ex
           puts "Could not update env vars due to #{ex} in #{app_hash}"
        end
      end

      builder.start_app(params[:new_name])

      sleep 2

      redirect "http://#{params[:new_name]}.cloudfoundry.com"
      #builder.upload_app(nil, extracted_dir)
      #builder.start_app(params[:app_name])
    #rescue Exception => ex
    #  puts "Error #{ex} pushing app"
    #end
  else
    redirect '/apps/#{app_name}/new_copy'
  end
end






require 'rubygems'
require 'sinatra'
require 'json'
require 'vmc/client'
require 'rack-flash'

require_relative 'lib/CloudFoundry/mongoid'
require_relative 'lib/CloudFoundry/app_info'
require_relative 'lib/CloudFoundry/app'
require_relative 'lib/CloudFoundry/app_clone_request'

require 'newrelic_rpm'

include CloudFoundry

enable :sessions
use Rack::Flash

configure do
  @@target = "api.cloudfoundry.com"
  CloudFoundry::Mongo.config
  box_app = AppInfo.new({
    :display_name => "box-sample-ruby-app",
    :admin_user => "seanrose",
    :admin_pass => "badbe",
    :app_urls => ["box-sample-ruby-app.cloudfoundry.com"],
    :thumb_url => "/images/box-rebuilt-ruby/75.png",
    :framework => 'sinatra',
    :description => "The Box sample app has a redesigned interface for interacting with your content on Box. It demonstrates usage of the main functions of the API, including file upload/download, account tree viewing, file preview, and more.",
    :git_repo => "https://github.com/cloudfoundry-samples/box-sample-ruby-app",
    :git_commit => "2614474",
    :git_branch => 'master',
    :starting_url => "https://www.box.com/developers/services",
    :env_vars => {'BOX_API_KEY' => 'enter your key here'}
  })
  qa_box_app = box_app.clone
  qa_box_app.display_name = "#{qa_box_app.display_name}-qa"

  box_app.save! unless (AppInfo.find_by_display_name(box_app.display_name))
  qa_box_app.save! unless (AppInfo.find_by_display_name(qa_box_app.display_name))

end

helpers do
  # Render views/404.haml
  not_found do
    @title = "404 - Not Found"
    haml :'not_found', :layout => :new_layout
  end

  def content_for(key, &block)
    @content ||= {}
    @content[key] = capture_haml(&block)
  end
  def content(key)
    @content && @content[key]
  end

  def authorized? app
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [app.admin_user, app.admin_pass]
  end

  def find_sample app_name
    #temp
    app_info = AppInfo.find_by_display_name(app_name)
    return app_info if app_info
    halt [404, "Could not find sample app name #{app_name}\n"]
  end

  def escaped_ext_email
    CGI::escape(params[:external_email])
  end

  def escaped_ext_app_name
    CGI::escape(params[:external_app_name])
  end

  def debug_log msg
    puts "[#{DateTime.now}] #{msg} for #{session[:email]} and app name #{params[:external_app_name]}"
  end
end


before do
  # Example of how to only allow https
  #unless (ENV['bypass_ssl'] && request.secure?)
  #  halt 401, 'This website can only be accessed over SSL'
  #end

  @title = "Gallery"
  @canonical_url = request.url
  @fb_app_id = ENV['facebook_app_id']
  @signup_url = "https://my.cloudfoundry.com/signup"

  if (session[:auth_token] && @vmcclient.nil? )
    @vmcclient = VMC::Client.new(@@target, session[:auth_token])
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

get '/' do
  redirect session[:path] || "http://www.cloudfoundry.com"
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
  redirect session[:path]
end

get '/logout' do
  session.delete :auth_token
  session.delete :email
  redirect session[:path]
end

# Called by the 3rd party server side to request url for developer
# Will always generate a new url
post '/apps/:app_name/reserve' do |app_name|
  @sample_app_info = find_sample app_name

  unless authorized? @sample_app_info
    response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
    halt [401, "Not authorized\n"]
  end

  halt [401, "Missing developer's app name"] unless params[:external_app_name] # name of app on the 3rd party service
  halt [401, "Missing developer's email"] unless params[:external_email]   #email for developer

  generated_name =  CloudFoundry::App.find_available_app_name(params[:external_email], params[:external_app_name] )

  @app_clone_request = nil
  if generated_name
    @app_clone_request = @sample_app_info.find_or_create_request_to_clone({
        request_email: params[:external_email],
        request_app_name: params[:external_app_name],
        cf_app_name:  generated_name
    })
  end

  unless @app_clone_request
    puts "Error requesting clone for #{@sample_app_info.inspect}"
    halt [401, "Could not find or create app deploy request for developer email= #{params[:external_email]} with app name = #{params[:external_app_name]}"]
  end

  return "http://#{@app_clone_request.cf_app_name}#{CloudFoundry::App::DEFAULT_CF}"
end

# Support the POST end point too !
post '/apps/:app_name/get_copy' do |app_name|
  vars = ''
  params.each do |key, val|
    if (key != 'app_name' && key != 'external_email')
      vars = "#{vars}&#{key}=#{val}"
    end
  end
  redirect "/apps/#{app_name}/get_copy?external_email=#{escaped_ext_email}#{vars}"
end

# Client side request initiated by 3rd party for developer to deploy
get '/apps/:app_name/get_copy' do |app_name|
  session[:path] = request.url

  @app_name = app_name
  @sample_app_info = find_sample app_name

  @env_vars = {}
  @sample_app_info.env_vars.each do |k,v|
    @env_vars[k] = params[k]
  end

  # All Apps must have promocodes :)
  @signup_url = "#{@signup_url}/#{@sample_app_info.promocode}"

  @title = @sample_app_info.display_name

  @fail = flash[:notice]
  unless (params[:external_app_name] || params[:external_email])
    @warn = "Unauthorized flow. Please start here:"
  else
    @app_clone_request = @sample_app_info.find_request_to_clone({request_email: params[:external_email], request_app_name: params[:external_app_name]})
    unless @app_clone_request
      @warn = "Could not find deploy request for credentials given. Please start here:"
    end
  end

  @current_app_name = @app_clone_request ? @app_clone_request.cf_app_name : ""
  haml :new_copy, :layout => :new_layout
end

get '/apps/:app_name/success' do |app_name|
  @sample_app_info = find_sample app_name
  @app_clone_request = @sample_app_info.find_request_to_clone({request_email: params[:external_email], request_app_name: params[:external_app_name]})
  @app_url = "http://#{@app_clone_request.cf_app_name}#{CloudFoundry::App::DEFAULT_CF}"
  @changed_name = true if params[:changed_name]
  haml :success, :layout => :new_layout
end


# Client side request submitted from get_copy
post '/apps/:app_name/deploy' do |app_name|

  @sample_app_info = find_sample app_name
  unless (params[:external_app_name] || params[:external_email])
    @warn = "Unauthorized flow. Please start here:"
  else
    @app_clone_request = @sample_app_info.find_request_to_clone({request_email: params[:external_email], request_app_name: params[:external_app_name]})
    unless @app_clone_request
      @warn = "Could not find deploy request for credentials given. Please start here:"
    else

      if (@vmcclient)
        begin
          @app_info = @sample_app_info.clone
          @app_info.app_urls = []

          @app_info.display_name = @app_clone_request.cf_app_name #params[:new_name]

          # Set all the env vars
          @app_info.env_vars.each do |var_name, val|
            @app_info.env_vars[var_name] = params[var_name]
          end

          app = CloudFoundry::App.new(@vmcclient, @app_info)
          if (params[:new_name] != @app_clone_request.cf_app_name)
            app.change_name! params[:new_name]
          end
          if (app.exists?)
            debug_log "App #{params[:new_name]} already exists. Skipping deployment"
            flash[:notice] = "Failed to deploy app #{params[:new_name]} because it already exists. Please select a new name to deploy if you need it."
          else
            debug_log "About to create App"
            app.create(:pick_another_name_if_taken => true)

            debug_log "Created App -- now copying code"
            app.copy_code

            debug_log "Copied Code -- now starting app"
            app.start

            debug_log "App Started -- now updating owner"
            @app_clone_request.update_attribute :cf_username, session[:email]
            debug_log "Owner Updated"


            @changed_name = false
            if (app.name_changed)
              debug_log "Changing name of app in records"
              @app_clone_request.update_attribute :cf_app_name, app.display_name
              debug_log "Done changing name"
              @changed_name = true
            end
            new_url = "/apps/#{app_name}/success?#{@changed_name ?"changed_name=1&" : ''}external_email=#{escaped_ext_email}&external_app_name=#{escaped_ext_app_name}"

            debug_log "Redirecting to #{new_url} changed_name is #{@changed_name}"
            redirect new_url
          end
        rescue Exception => ex
          debug_log "Error #{ex} pushing app for #{session[:email]} More at: #{ex.inspect}"
          flash[:notice] = "Failed to deploy app #{params[:new_name]} due to #{ex} please check name requested and try again."
        end
      else
        @warn = "Please Log In before deploying"
      end
    end
    redirect session[:path]
  end
end






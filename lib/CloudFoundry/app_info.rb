module CloudFoundry
  class AppInfo
    include Mongoid::Document
    #include Mongoid::Timestamps
    #
    #has_and_belongs_to_many :service_infos
    #has_many :app_health_snapshots
    #belongs_to :ogp_description
    embeds_many :app_clone_requests

    field :app_id, :type => Integer
    field :app_urls, :type => Array
    field :thumb_url, :type => String
    field :admin_user, :type => String
    field :admin_pass, :type => String
    field :display_name, :type => String
    field :description, :type => String
    field :instances, :type => Integer, :default => 1
    field :memory, :type => Integer, :default => 128
    field :runtime, :type => String
    field :framework, :type => String

    field :git_repo, :type => String
    field :git_branch, :type => String
    field :git_commit, :type => String

    field :browseable, :type => Boolean
    field :cloneable, :type => Boolean

    field :env_vars, :type => Hash

    field :starting_url, :type => String


    index :app_id, :unique => true
    index :display_name, :unique => true

    def repo_name
      git_repo.gsub(/https\:\/\/github.com\//, '').gsub(/\//, "-")
    end

    def env_array
      # So developers know where to get the code from
      array = ["SOURCE_GIT_REPO=#{git_repo}", "SOURCE_GIT_COMMIT=#{git_commit}", "SOURCE_GIT_BRANCH=#{git_branch}"]
      env_vars.each do |key,val|
        array << "#{key}=#{val}"
      end

      array
    end

    def promocode
      display_name.gsub /[\s\-\_]/, ''
    end

    def self.find_by_display_name display_name
      AppInfo.where(:display_name => display_name).first
    end

    def find_request_to_clone options={}
      app_clone_requests.each do |req|
        return req if (req.request_app_name == options[:request_app_name] && req.request_email == options[:request_email])
      end
      nil
    end

    def find_or_create_request_to_clone options={}
      req = find_request_to_clone options
      return req if req

      return app_clone_requests.create(options)

    end

  #  def get_memory_for_framework
  #    case @framework
  #      when "sinatra"
  #        return 128
  #      when "rails3"
  #        return 256
  #      when "spring"
  #      when "java_web"
  #      when "lift"
  #      when "grails"
  #        return 512
  #      when "node"
  #        return 64
  #      else
  #        return 256
  #      end
  #    end
  end
end

module CloudFoundry
  class AppInfo
    include Mongoid::Document

    embeds_many :app_clone_requests
    belongs_to :repo, :class_name => "GitHub::RepositorySnapshot"

    field :app_id, :type => Integer
    field :app_urls, :type => Array
    field :display_name, :type => String
    field :description, :type => String
    field :instances, :type => Integer, :default => 1
    field :memory, :type => Integer, :default => 128
    field :runtime, :type => String
    field :framework, :type => String
    field :env_vars, :type => Hash

    field :thumb_url, :type => String
    field :admin_user, :type => String
    field :admin_pass, :type => String
    field :browseable, :type => Boolean
    field :cloneable, :type => Boolean
    field :starting_url, :type => String

    index :display_name, :unique => true

    validates_presence_of :display_name, :runtime, :framework
    validates_presence_of :repo, :if => :cloneable

    def env_array
      # So developers know where to get the code from
      array = repo.to_env_array
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

    def create_or_update_attributes!
      current_app = AppInfo.find_by_display_name(self.display_name)
      if (current_app)
        if (current_app.repo != self.repo)
          current_app.repo = self.repo
          current_app.save!
        end
      else
        self.save!
      end
  end
  end
end

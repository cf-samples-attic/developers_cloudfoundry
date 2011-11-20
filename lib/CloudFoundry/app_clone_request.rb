class AppCloneRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :app_info

  field :request_email, :type => String
  field :request_app_name, :type => String
  field :cf_app_name, :type => String
  field :username, :type => String

  validates_presence_of :request_email
  validates_presence_of :request_app_name

  def self.find_or_create sample_app_info, options
    sample_app_info.reload.app_clone_requests.each do |req|
      return req if (req.request_app_name == options[:request_app_name] && req.request_email == options[:request_email])
    end
    req = sample_app_info.app_clone_requests.build(options)
    parts = sample_app_info.app_urls.first.split('.')
    a,b = req.request_email.split '@'
    req.cf_app_name = parts[0] + "-#{sample_app_info.git_commit}-" + a
    req.save!
    return req.reload
  end

end
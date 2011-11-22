class AppCloneRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :app_info

  field :request_email, :type => String
  field :request_app_name, :type => String
  field :cf_app_name, :type => String
  field :username, :type => String
  field :external_app_url, :type => String

  validates_presence_of :request_email
  validates_presence_of :request_app_name

end
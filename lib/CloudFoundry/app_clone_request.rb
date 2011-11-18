class AppCloneRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :app_info

  field :request_email, :type => String
  field :request_app_name, :type => String
  field :cf_app_name, :type => String

  validates_presence_of :request_email
  validates_presence_of :request_app_name

  set_callback(:save, :before) do |document|
    document.generate_cf_app_name unless cf_app_name
  end

  def generate_cf_app_name
    if request_email
      a,b = request_email.split '@'
      cf_app_name = parts[0] + "-#{app_info.git_commit}-" + a
    end
  end

end
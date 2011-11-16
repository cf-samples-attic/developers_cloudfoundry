require 'mongoid'

class App
  include Mongoid::Document
  #include Mongoid::Timestamps
  #
  #has_and_belongs_to_many :service_infos
  #has_many :app_health_snapshots
  #belongs_to :ogp_description

  field :app_id, :type => Integer
  field :app_urls, :type => Array
  field :app_type, :type => String
  field :display_name, :type => String
  field :description, :type => String
  field :instances, :type => Integer, :default => 1
  field :memory, :type => Integer, :default => 128
  field :runtime, :type => String
  field :framework, :type => String
  field :git_repo, :type => String
  field :browseable, :type => Boolean
  field :cloneable, :type => Boolean

  field :env_vars, :type => Hash

  index :app_id, :unique => true
  index :display_name, :unique => true
end

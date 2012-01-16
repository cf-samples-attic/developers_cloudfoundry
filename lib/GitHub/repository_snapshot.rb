module GitHub
  class RepositorySnapshot
    include Mongoid::Document
    has_many :app_infos

    field :url, :type => String
    field :name, :type => String
    field :branch, :type => String, :default => 'master'
    field :tag, :type => String
    field :commit, :type => String

    index :url, :unique => true

    validates_presence_of :url, :name, :commit, :branch

    def url=(value)
      name = value.gsub(/https\:\/\/github.com\//, '').gsub(/\//, "-")
      write_attribute(:name, name)
      write_attribute(:url, value)
    end

    def tag_or_branch
      tag || branch
    end

    def to_env_array
      ["SOURCE_GIT_REPO=#{url}", "SOURCE_GIT_TAG=#{tag}","SOURCE_GIT_COMMIT=#{commit}", "SOURCE_GIT_BRANCH=#{branch}"]
    end

    def zip_url
      "#{url}/zipball/#{tag_or_branch}"
    end

  end
end
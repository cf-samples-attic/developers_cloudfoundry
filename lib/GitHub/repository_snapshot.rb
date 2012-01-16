module GitHub
  class RepositorySnapshot
    include Mongoid::Document

    field :url, :type => String
    field :name, :type => String
    field :parent, :type => String
    field :branch, :type => String, :default => 'master'
    field :tag, :type => String
    field :commit, :type => String

    index :url, :unique => true

    validates_presence_of :url, :name, :parent, :commit, :branch

    def url=(value)
      parts = value.gsub(/https\:\/\/github.com\//, '').split('/')
      if (parts.length == 2)
        write_attribute(:parent, parts[0])
        write_attribute(:name, parts[1])
      else
        write_attribute(:parent, nil)
        write_attribute(:name, nil)
      end
      write_attribute(:url, value)
    end

    def local_name
      "#{parent}-#{name}"
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
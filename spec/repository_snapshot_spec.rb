require_relative '../lib/CloudFoundry/mongoid'
require_relative '../lib/tmp_zip'
require_relative '../lib/GitHub/repository_snapshot'

describe "RepositorySnapshot" do

  it "Should properly instantiate a RepositorySnapshot class" do
    obj = GitHub::RepositorySnapshot.new
    obj.class.should == GitHub::RepositorySnapshot
  end

  it "Should require Url and Commit to save" do
    obj = GitHub::RepositorySnapshot.new
    obj.should_not be_valid

    obj.url = "https://github.com/ciberch/janky"
    obj.commit = "23232fg"

    obj.should be_valid
    obj.name.should ==  "janky"
    obj.parent.should == "ciberch"
  end

  it "Should only be cloneable if it has the GitHub Repo Info" do
    obj = GitHub::RepositorySnapshot.new :url => "https://github.com/cloudfoundry-samples/box-sample-ruby-app"

    obj.should_not be_valid
    obj.commit = "abcdef"
    obj.should be_valid
    obj.url = ''
    obj.should_not be_valid
    obj.name.should be_nil
    obj.parent.should be_nil

  end

  it "doesn't accept invalid github repo urls" do
    obj = GitHub::RepositorySnapshot.new :url => "https://google.com"
    obj.should_not be_valid
    obj.name.should be_nil
    obj.parent.should be_nil
  end

  describe "Downloads" do
    after(:all) do
      FileUtils.rm_rf(Dir["#{Dir.tmpdir}/*"])
    end

    it "can download the repo snapshot" do
      obj = GitHub::RepositorySnapshot.new :url => "https://github.com/cloudfoundry-samples/box-sample-ruby-app", :commit => 'e84963c', :tag => 'v1.0'

      obj.has_download?.should be_false

      obj.download!
      obj.has_download?.should be_true
    end

    it "should not download the repo again" do
      obj = GitHub::RepositorySnapshot.new :url => "https://github.com/cloudfoundry-samples/box-sample-ruby-app", :commit => 'e84963c', :tag => 'v1.0'
      obj.has_download?.should be_true
      obj.download!
      obj.has_download?.should be_true
    end
  end
end
require_relative '../lib/CloudFoundry/mongoid'
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
end
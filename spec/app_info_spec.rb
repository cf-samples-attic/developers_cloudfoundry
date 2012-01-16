require_relative '../lib/CloudFoundry/mongoid'
require_relative '../lib/CloudFoundry/app_info'
require_relative '../lib/CloudFoundry/app_clone_request'
require_relative '../lib/GitHub/repository_snapshot'

describe "AppInfo" do

  it "Should properly instantiate an AppInfo class with an App Clone Requests Collection" do
    obj = CloudFoundry::AppInfo.new
    obj.class.should == CloudFoundry::AppInfo
    obj.app_clone_requests.should == []
  end

  it "Should require Display Name, Runtime and Framework to save" do
    obj = CloudFoundry::AppInfo.new
    obj.should_not be_valid

    obj.display_name = "Spaceship"
    obj.runtime = "ruby19"
    obj.framework = "sinatra"

    obj.should be_valid
  end

  it "Should only be cloneable if it has the GitHub Repo Info" do
    obj = CloudFoundry::AppInfo.new :app_id => 10, :display_name => "Spaceship", :runtime => 'ruby19', :framework => 'sinatra', :cloneable => true
    obj.should_not be_valid

    obj.repo = GitHub::RepositorySnapshot.new :url => "https://github.com/cloudfoundry-samples/box-sample-ruby-app", :commit => "e84963c", :tag => 'v1.0'

    obj.should be_valid
  end
end
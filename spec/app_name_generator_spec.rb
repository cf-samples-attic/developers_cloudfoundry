require_relative '../lib/CloudFoundry/app_name_generator'
require 'rest-client'

describe "AppNameGenerator" do

  it "Should properly instantiate a AppNameGenerator class" do
    obj = CloudFoundry::AppNameGenerator.new "monica is so cool", "mo", "ciberch@yahoo.com"
    obj.class.should == CloudFoundry::AppNameGenerator
    obj.name.should == "monica is so cool"
  end

  it "Replaces spaces or underscores with dashes" do
    obj = CloudFoundry::AppNameGenerator.new "monica is so_cool", "mo", "ciberch@yahoo.com"
    obj.class.should == CloudFoundry::AppNameGenerator
    obj.clean_name.should == "monica-is-so-cool"
  end

  it "Only does Max Tries(10)" do
    obj = CloudFoundry::AppNameGenerator.new "monica is so_cool", "mo", "ciberch@yahoo.com"
    obj.class.should == CloudFoundry::AppNameGenerator
    obj.next.should == "monica-is-so-cool-ciberch"
    obj.next.should == "monica-is-so-cool-2"
    obj.next.should == "monica-is-so-cool-3"
    obj.next.should == "monica-is-so-cool-4"
    obj.next.should == "monica-is-so-cool-5"
    obj.next.should == "monica-is-so-cool-6"
    obj.next.should == "monica-is-so-cool-7"
    obj.next.should == "monica-is-so-cool-8"
    obj.next.should == "monica-is-so-cool-9"
    obj.next.should == "monica-is-so-cool-10"
    obj.next.should be_nil
  end

  it "Reads the base index" do
    obj = CloudFoundry::AppNameGenerator.new "app3", "mo", "ciberch@yahoo.com"
    obj.class.should == CloudFoundry::AppNameGenerator
    obj.base_name.should == "app"
    obj.base_index.should == 3
    obj.next.should == "app-4"
    obj.next.should == "app-5"
  end

  it "Replaces spaces with dashes" do
    obj = CloudFoundry::AppNameGenerator.new "monica is so cool", "mo", "ciberch@yahoo.com"
    obj.class.should == CloudFoundry::AppNameGenerator
    obj.clean_name.should == "monica-is-so-cool"
  end

   it "Properly figures out which app name is available" do
     obj = CloudFoundry::AppNameGenerator.new "monica is so cool", "mo", "ciberch@yahoo.com"
     obj.find_available_app_name.should == "monica-is-so-cool"
   end

   it "Properly figures out which app name is in use" do
     obj = CloudFoundry::AppNameGenerator.new "www", "mo", "prettyponies123@yahoo.com"
     obj.find_available_app_name.should == "www-prettyponies123"
   end

end
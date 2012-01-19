# Cloud Foundry Open Source Gallery App
This is the repository for the Cloud Foundry Open Source Gallery App.
The goal of the Cloud Foundry Gallery App is to make it easier for developers to try each others apps and products by
allowing them to clone and publish Open Source Sample Apps from Github which are listed in the catalog.

Under the covers, the Gallery App is a Ruby Application which uses the Sinatra framework, MongoDB and VMC to deploy
GitHub projects to any Cloud Foundry instance.

## Configuration
The default instance is "cloudfoundry.com"  but you can switch it by changing the environment variable `ENV['cloud']`
You can also edit `@@clouds` for the list of cloud choices you want to make available

Also note that this app does not need to be running on Cloud Foundry to deploy another app to Cloud Foundry
This app is simply an API client. Therefore you can deploy this app in a different cloud that your target cloud

# Gallery Operations

## Step 1 - Adding the project to the Gallery

Audience: Developer of 3rd party platform, service or app
Submit a pull request with your project(s). Once it gets approved you will get a set of credentials and the app will be deployed to the catalog on
http://gallery.cloudfoundry.com

If you want to allow developers to auto deploy to Cloud Foundry from your service you must do the following from your App Deployment Wizard

### Request

`POST /apps/<your_app_name>/reserve`

* Include via Basic Auth the username and password given to your by the Gallery App Host
* external_email (Email for the developer)
* external_app_name (Desired name of the app for the developer)
* Env Vars should be passed as parameters

### Response

* `200 OK` with a valid app name as the text of the body. Ex: `http://www-peter.cloudfoundry.com`   or
* `401 Unauthorized` if the credentials are incorrect

## Deploying the project

Target Actor: 3rd party platform App Editor

### Request

GET https://cloner.cloudfoundry.com/apps/box-sample-ruby-app/get_copy

* external_email (Email for the developer)
* external_app_name (Desired name of the app)
* Env Vars should be passed as parameters




##Current Status and TODOs

The gallery currently supports deploying projects which contain the complete list of packages or gems in the GitHub repo.
For example a Ruby or Node.js project. We have not yet extended it for Java apps


## Getting Started
If you would like to contribute to this project please following these steps:

* Setup git http://help.github.com/mac-set-up-git/
* Clone the repository to your local machine if you haven't already

### Running the Application Locally

* cd into the directory you just cloned `cd gallery`
* Install the gems for the project `bundle install`
* Run the website.rb file with `shotgun`
* Open a browser to http://127.0.0.1:9393/


### Making changes to the codebase
* Create an Issue
* Create a branch of master and name it after the thing you are working on. Example:

  ```bash
  git checkout master
  git pull origin master
  git checkout -b fix-calendar-links
  ```

* Make changes and test locally. You can run the webserver by issuing this command:  `shotgun`
* You can make changes and reload the pages without restarting the webserver

* Commit once you have tested. It is good to commit often but it should be a logical unit of work. 
** Make sure you add comments

  ```
  git commit -am "Fix for view in IE9"
  git push origin head
  ```

* When you are done with the feature or bug. Submit a pull on github.com include a link to the ticket this pull request resolves
* Someone else on the team will take care of reviewing the request and will comment directly on github
* Once all the changes are handled the code can be pushed to the production app


## Deploying this app to CloudFoundry
First read http://start.cloudfoundry.com/tools/vmc/installing-vmc.html
Make sure you have the latest vmc version because we use Manifest
http://blog.cloudfoundry.com/post/13481010498/simplified-application-deployment-with-cloud-foundry-manifest

  ```bash
  vmc login <username>
  vmc push <app_name> --runtime=ruby19
  ```


  After some changes
  ```bash
  vmc update <app_name>
  ```

# Tagging for Release to Production to be done by lead committer

  ```bash
  git tag -a v1.0
  git push origin v1.0
  ```



# Overview
This is the repository for gallery.cloudfoundry.com. It is a basic Ruby Application which uses the Sinatra framework.
The rendering template we have decided to use is haml. To learn more about haml please visit haml.org

# Ongoing development
If you would like to contribute to this project please following these steps:

* Setup git http://help.github.com/mac-set-up-git/ 
* Clone the repository to your local machine if you haven't already

## Running the Application Locally

* cd into the directory you just cloned `cd gallery`
* Install the gems for the project `bundle install`
* Run the website.rb file with `shotgun`
* Open a browser to http://127.0.0.1:9393/


## Making changes to the codebase
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
  git commit -am "Fix for underlining of links in IE9"
  git push origin head
  ```

* When you are done with the feature or bug. Submit a pull on github.com include a link to the ticket this pull request resolves
* Someone else on the team will take care of reviewing the request and will comment directly on github
* Once all the changes are handled the code can be pushed to the production app


# Pushing to CloudFoundry
First read http://start.cloudfoundry.com/tools/vmc/installing-vmc.html

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

Where `origin` is the remote and `v1.0` is the incremented version


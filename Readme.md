Canvas LMS
======

Canvas is a new, open-source LMS by Instructure Inc. It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

Minimal installation instructions (if you have a Rails environment set up, with mysql etc):
  * This package uses bundler (http://gembundler.com/) 
    gem install bundler  
    bundle install
  * set up default config files
    for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security; do \
    cp config/$config.yml.example config/$config.yml; done
  * set up database config
    cp config/database.yml.sqlite-example config/database.yml
  * populate database (will also ask you for admin user data)
    rake db:initial_setup
  * Run!
    script/server

[For a much more detailed tutorial, olease see our main wiki page](http://github.com/instructure/canvas-lms/wiki).

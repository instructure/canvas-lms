source :rubygems

ONE_NINE = RUBY_VERSION >= "1.9."

gem 'rails',          '2.3.14'
gem 'authlogic',      '2.1.3'
#gem 'aws-s3',         '0.6.2',  :require => 'aws/s3'
# use custom gem until pull request at https://github.com/marcel/aws-s3/pull/41
# is merged into mainline. gem built from https://github.com/lukfugl/aws-s3
gem "aws-s3-instructure", "0.6.2.1352914936",  :require => 'aws/s3'
gem 'barby',          '0.5.0'
gem 'bcrypt-ruby',    '3.0.1'
gem 'builder',        '2.1.2'
gem 'daemons',        '1.1.0'
gem 'diff-lcs',       '1.1.2',  :require => 'diff/lcs'
gem 'encrypted_cookie_store-instructure', '1.0.2', :require => 'encrypted_cookie_store'
gem 'erubis',         '2.7.0'
gem 'ffi',            '1.1.5'
gem 'hairtrigger',    '0.1.14'
if !ONE_NINE
  gem 'fastercsv', '1.5.3'
end
gem 'hashery',        '1.3.0',  :require => 'hashery/dictionary'
gem 'highline',       '1.6.1'
gem 'i18n',           '0.6.0'
gem 'icalendar',      '1.1.5'
gem 'jammit',         '0.6.0'
gem 'json',           '1.5.2'
# native xml parsing, diigo
gem 'libxml-ruby',    '2.3.2',  :require => 'xml/libxml'
gem 'macaddr',        '1.0.0'  # macaddr 1.2.0 tries to require 'systemu' which isn't a dependency
if !ONE_NINE
  # mail gem v2.5.* introduces a failure on 1.8 with bad unicode in headers
  gem 'mail', '2.4.4'
end
gem 'mailman',        '0.5.3'
gem 'mime-types',     '1.17.2',   :require => 'mime/types'
# attachment_fu (even the current technoweenie one on github) does not work
# with mini_magick 3.1
gem 'mini_magick',    '1.3.2'
gem 'netaddr',        '1.5.0'
gem 'nokogiri',       '1.5.5'
gem 'oauth',          '0.4.5'
gem 'rack',           '1.1.3'
gem 'rake',           '< 0.10'
gem 'rdoc',           '3.12' #it seems like you shouldn't need this, at least not all the time
gem 'ratom-instructure', '0.6.9', :require => "atom" # custom gem until necessary changes are merged into mainstream
if !ONE_NINE
  gem 'rbx-require-relative', '0.0.5'
end
gem 'rdiscount',      '1.6.8'
gem 'require_relative', '1.0.1'
gem 'ritex',          '1.0.1'
gem 'rotp',           '1.4.1'
gem 'rqrcode',        '0.4.2'
gem 'rscribd',        '1.2.0'
gem 'net-ldap',       '0.3.1',  :require => 'net/ldap'
gem 'ruby-saml-mod',  '0.1.19'
gem 'rubycas-client', '2.2.1'
gem 'rubyzip',        '0.9.4',  :require => 'zip/zip'
gem 'sanitize',       '2.0.3'
gem 'uuid',           '2.3.2'
gem 'will_paginate',  '2.3.15'
gem 'xml-simple',     '1.0.12', :require => 'xmlsimple'
# this is only needed by jammit, but we're pinning at 0.9.4 because 0.9.5 breaks
gem 'yui-compressor', '0.9.4', :require => false
gem 'foreigner',      '0.9.2'
gem 'crocodoc-ruby',  '0.0.1', :require => 'crocodoc'

group :mysql do
  gem 'mysql',        '2.8.1'
end

group :postgres do
  gem 'pg',           '0.10.1'
end

group :sqlite do
  gem 'sqlite3-ruby', '1.3.2'
end

# Off the top of my head, I forgot if these things will be required when you start rails
# but look at: http://gembundler.com/v1.2/groups.html and make sure you do whatever you need
# to do so that script/* and rake dont load any of these.

group :guard do
  gem 'compass' # will pull in sass for you, note that you DON'T need compass-rails at all if 
                # you are letting guard do your compilation for you.  this is the main change here
                # the normal sass/compass way of doing things in a rails project is to make sure on every page load
                # that it has made each css file that the page is going to need, since you guard doing that kind of stuff
                # in a seperate process anyway, and doing it on a file modification basis and not on a page load basis
                # you can just let rails work with the static generated css, like you do with the js your coffeescript guard
                # generates.
  
  gem 'bootstrap-sass', '2.0.3.1'
  gem 'guard'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'guard-coffeescript' # canvas has its own hacked guard-coffeescript, I think to support our vendor/plugins assets.
                           # but even if you use it instead of this, make sure it only gets loaded by guard and not normal script/server
  gem 'guard-livereload' # I was using this one in my own custom guardfile there, and it's awesome!
  gem 'guard-sass' # or maybe use guard-compass, I forgot which one is the best
end

group :test do
  gem 'coffee-script'
  gem 'coffee-script-source',  '1.3.1' #pinned so everyone's compiled output matches
  gem 'bluecloth',    '2.0.10' # for generating api docs
  gem 'parallel',     '0.5.16'
  gem 'parallelized_specs', '0.3.86'
  gem 'mocha',        '0.12.3', :require => 'mocha_standalone'
  gem 'rcov',         '0.9.9'
  gem 'rspec',        '1.3.2'
  gem 'rspec-rails',  '1.3.4'
  gem 'selenium-webdriver', '2.26.0'
  gem 'webrat',       '0.7.3'
  gem 'yard',         '0.8.0'
  if ONE_NINE
    gem 'test-unit',  '1.2.3'
  end
end

group :development do
  gem 'coffee-script'
  gem 'coffee-script-source',  '1.3.1' #pinned so everyone's compiled output matches
  gem 'parallel',     '0.5.16'
  if ONE_NINE
    gem 'debugger',     '1.1.3'
  else
    gem 'ruby-debug',   '0.10.4'
  end
end

group :i18n_tools do
  gem 'ruby_parser', '2.0.6'
  gem 'sexp_processor', '3.0.5'
  gem 'ya2yaml', '0.30'
end

group :redis do
  gem 'instructure-redis-store', '1.0.0.2.instructure1', :require => 'redis-store'
  gem 'redis', '3.0.1'
end

group :cassandra do
  gem 'cassandra-cql', '1.1.1'
end

group :embedly do
  gem 'embedly', '1.5.5'
end

group :statsd do
  gem 'statsd-ruby', '1.0.0', :require => 'statsd'
end

# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__),'vendor/plugins/*/Gemfile')].each do |g|
  eval(File.read(g))
end

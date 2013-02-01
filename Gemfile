source :rubygems

ONE_NINE = RUBY_VERSION >= "1.9."

gem 'rails',          '2.3.16'
gem 'authlogic',      '2.1.3'
#gem 'aws-s3',         '0.6.2',  :require => 'aws/s3'
# use custom gem until pull request at https://github.com/marcel/aws-s3/pull/41
# is merged into mainline. gem built from https://github.com/lukfugl/aws-s3
gem "aws-s3-instructure", "0.6.2.1352914936",  :require => 'aws/s3'
gem 'barby',          '0.5.0'
gem 'bcrypt-ruby',    '3.0.1'
gem 'builder',        '2.1.2'
gem 'canvas_connect'
gem 'daemons',        '1.1.0'
gem 'diff-lcs',       '1.1.2',  :require => 'diff/lcs'
gem 'encrypted_cookie_store-instructure', '1.0.2', :require => 'encrypted_cookie_store'
gem 'erubis',         '2.7.0'
gem 'ffi',            '1.1.5'
gem 'hairtrigger',    '0.1.14'
gem 'sass',           '3.2.1'
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
gem 'rdoc',           '3.12'
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
gem 'rubyzip',        '0.9.5',  :require => 'zip/zip'
gem 'sanitize',       '2.0.3'
gem 'uuid',           '2.3.2'
gem 'will_paginate',  '2.3.15'
gem 'xml-simple',     '1.0.12', :require => 'xmlsimple'
# this is only needed by jammit, but we're pinning at 0.9.4 because 0.9.5 breaks
gem 'yui-compressor', '0.9.4'
gem 'foreigner',      '0.9.2'
gem 'crocodoc-ruby',  '0.0.1', :require => 'crocodoc'

group :assets do
  gem 'compass-rails', '1.0.2'
  gem 'bootstrap-sass', '2.0.3.1'
end

group :mysql do
  gem 'mysql',        '2.8.1'
end

group :postgres do
  gem 'pg',           '0.10.1'
end

group :sqlite do
  gem 'sqlite3-ruby', '1.3.2'
end

group :test do
  gem 'bluecloth',    '2.0.10' # for generating api docs
  gem 'parallelized_specs', '0.3.98'
  gem 'mocha',        '0.12.3', :require => 'mocha_standalone'
  gem 'rcov',         '0.9.9'
  gem 'rspec',        '1.3.2'
  gem 'rspec-rails',  '1.3.4'
  gem 'selenium-webdriver', '2.27.2'
  gem 'webrat',       '0.7.3'
  gem 'yard',         '0.8.0'
  gem 'timecop',      '0.5.9.1'
  if ONE_NINE
    gem 'test-unit',  '1.2.3'
  end
end

group :development do
  gem 'guard', '1.6.0'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  if ONE_NINE
    gem 'debugger',     '1.1.3'
  else
    gem 'ruby-debug',   '0.10.4'
  end
end

group :development, :test do
  gem 'coffee-script'
  gem 'coffee-script-source',  '1.4.0' #pinned so everyone's compiled output matches
  gem 'parallel',     '0.5.16'
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

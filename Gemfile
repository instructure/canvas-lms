source 'https://rubygems.org/'

if RUBY_VERSION < "1.9.3" || RUBY_VERSION >= "2.0"
  raise "Canvas requires Ruby 1.9.3"
end

ONE_NINE = RUBY_VERSION >= "1.9."
require File.expand_path("../config/canvas_rails3", __FILE__)

if CANVAS_RAILS3
  # 3.0.20 is transitional, we will be on 3.2.x before support is complete
  # that's also why some gems below have to be downgraded, 3.0.20 relies on old versions of some gems
  # just to be clear, Canvas is NOT READY to run under Rails 3 in production
  gem 'rails',        '3.0.20'
  gem 'authlogic',    '3.2.0'
else
  gem 'rails',        '2.3.18'
  gem 'authlogic',    '2.1.3'
end

gem "aws-sdk",        '1.8.3.1'
gem 'barby',          '0.5.0'
gem 'bcrypt-ruby',    '3.0.1'
gem 'builder',        '2.1.2'
if !CANVAS_RAILS3
  gem 'canvas_connect', '0.1.0'
end
gem 'daemons',        '1.1.0'
gem 'diff-lcs',       '1.1.3',  :require => 'diff/lcs'
if !CANVAS_RAILS3
  gem 'encrypted_cookie_store-instructure', '1.0.2', :require => 'encrypted_cookie_store'
end
gem 'erubis',         CANVAS_RAILS3 ? '2.6.6' : '2.7.0'
if !CANVAS_RAILS3
  gem 'fake_arel',      '1.0.0'
end
gem 'ffi',            '1.1.5'
gem 'hairtrigger',    '0.2.3'
gem 'sass',           '3.2.3'
if !ONE_NINE
  gem 'fastercsv', '1.5.3'
end
gem 'hashery',        '1.3.0',  :require => 'hashery/dictionary'
gem 'highline',       '1.6.1'
gem 'i18n',           CANVAS_RAILS3 ? '0.5.0' : '0.6.0'
gem 'icalendar',      '1.1.5'
gem 'jammit',         '0.6.0'
gem 'json',           '1.5.5'
# native xml parsing, diigo
gem 'libxml-ruby',    '2.6.0',  :require => 'xml/libxml'
gem 'macaddr',        '1.0.0'  # macaddr 1.2.0 tries to require 'systemu' which isn't a dependency
if ONE_NINE
  gem 'mail', CANVAS_RAILS3 ? '2.2.19' : '2.5.3'
else
  gem 'mail', '2.4.4'
end
gem 'mailman',        '0.5.3'
# using this forked gem until https://github.com/37signals/marginalia/pull/15 is in the source gem
gem 'instructure-marginalia',     '1.1.3',    :require => false
gem 'mime-types',     '1.17.2',   :require => 'mime/types'
# attachment_fu (even the current technoweenie one on github) does not work
# with mini_magick 3.1
gem 'mini_magick',    '1.3.2'
gem 'netaddr',        '1.5.0'
gem 'nokogiri',       '1.5.6'
# oauth gem, with rails3 fixes rolled in
gem 'oauth-instructure', '0.4.9', :require => 'oauth'
gem 'rack',           CANVAS_RAILS3 ? '1.2.5' : '1.1.3'
gem 'rake',           '10.0.4'
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
gem 'ruby-saml-mod',  '0.1.22'
gem 'rubycas-client', '2.2.1'
gem 'rubyzip',        '0.9.5',  :require => 'zip/zip'
gem 'safe_yaml-instructure', '0.8.0',  :require => false
gem 'sanitize',       '2.0.3'
gem 'shackles',       '1.0.0'
gem 'tzinfo',         '0.3.35'
gem 'useragent',      '0.4.16'
gem 'uuid',           '2.3.2'
gem 'will_paginate',  '2.3.15'
gem 'xml-simple',     '1.0.12', :require => 'xmlsimple'
# this is only needed by jammit, but we're pinning at 0.9.4 because 0.9.5 breaks
gem 'yui-compressor', '0.9.4'
gem 'foreigner',      '0.9.2'
gem 'crocodoc-ruby',  '0.0.1', :require => 'crocodoc'

group :assets do
  gem 'compass-rails', '1.0.3'
  gem 'dress_code', '1.0.2'
end

group :mysql do
  gem 'mysql',        '2.8.1'
  gem 'mysql2',       '0.2.18'
end

group :postgres do
  gem 'pg',           '0.15.0'
end

group :sqlite do
  gem 'sqlite3-ruby', '1.3.2'
end

group :test do
  gem 'bluecloth',    '2.0.10' # for generating api docs
  gem 'mocha',        :git => 'git://github.com/ccutrer/mocha.git', :require => false
  gem 'parallelized_specs', '0.4.52'
  gem 'rcov',         '0.9.9'
  if CANVAS_RAILS3
    gem 'rspec-rails',  '2.13.0'
  else
    gem 'rspec',        '1.3.2'
    gem 'rspec-rails',  '1.3.4'
  end
  gem 'selenium-webdriver', '2.31.0'
  gem 'webrat',       '0.7.3'
  gem 'yard',         '0.8.0'
  gem 'yard-appendix',  '>=0.1.8'
  gem 'timecop',      '0.5.9.1'
  if ONE_NINE
    gem 'test-unit',  '1.2.3'
  end
end

group :development do
  gem 'guard', '1.6.0'
  gem 'rb-inotify', '~>0.9.0', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.
  unless ENV['DISABLE_RUBY_DEBUGGING']
    if ONE_NINE
      gem 'debugger',     '1.1.3'
    else
      gem 'ruby-debug',   '0.10.4'
    end
  end
end

group :development, :test do
  gem 'coffee-script'
  gem 'coffee-script-source',  '1.6.2' #pinned so everyone's compiled output matches
  gem 'parallel',     '0.5.16'
end

group :i18n_tools do
  gem 'ruby_parser', '3.1.3'
  gem 'sexp_processor', '4.2.1'
  gem 'ya2yaml', '0.30'
end

group :redis do
  gem 'instructure-redis-store', '1.0.0.2.instructure1', :require => 'redis-store'
  gem 'redis', '3.0.1'
end

group :cassandra do
  gem 'cassandra-cql', '1.1.5'
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

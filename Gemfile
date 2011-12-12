source :rubygems

gem 'rails',          '2.3.14'
gem 'authlogic',      '2.1.3'
#gem 'aws-s3',         '0.6.2',  :require => 'aws/s3'
# use custom gem until pull request at https://github.com/marcel/aws-s3/pull/41
# is merged into mainline. gem built from https://github.com/lukfugl/aws-s3
gem "aws-s3-instructure", "~> 0.6.2.1319643167",  :require => 'aws/s3'
gem 'bcrypt-ruby',    '3.0.1'
gem 'builder',        '2.1.2'
gem 'closure-compiler','1.0.0'
gem 'compass',        '0.11.5'
gem 'daemons',        '1.1.0'
gem 'diff-lcs',       '1.1.2',  :require => 'diff/lcs'
gem 'erubis',         '2.7.0'
gem 'hairtrigger',    '0.1.12'
gem 'haml',           '3.1.2'
gem 'hashery',        '1.3.0',  :require => 'hashery/dictionary'
gem 'highline',       '1.6.1'
gem 'hpricot',        '0.8.2'
gem 'i18n',           '0.6.0'
gem 'icalendar',      '1.1.5'
gem 'jammit',         '0.6.0'
gem 'json',           '1.5.2'
# native xml parsing, diigo
gem 'libxml-ruby',    '1.1.3',  :require => 'xml/libxml'
gem 'macaddr',        '1.0.0'  # macaddr 1.2.0 tries to require 'systemu' which isn't a dependency
gem 'mailman',        '0.4.0'
gem 'mime-types',     '1.16',   :require => 'mime/types'
# attachment_fu (even the current technoweenie one on github) does not work
# with mini_magick 3.1
gem 'mini_magick',    '1.3.2'
gem 'netaddr',        '1.5.0'
gem 'nokogiri',       '1.4.1'
gem 'oauth',          '0.4.5'
gem 'rack',           '~> 1.1.2' # rails requires ~> 1.1.0 but 1.1.0 has a param quoting bug
gem 'rake',           '< 0.10'
gem 'ratom-instructure', '0.6.9', :require => "atom" # custom gem until necessary changes are merged into mainstream
gem 'rdiscount',      '1.6.8'
gem 'require_relative', '1.0.1'
gem 'ritex',          '1.0.1'
gem 'rscribd',        '1.2.0'
gem 'ruby-net-ldap',  '0.0.4',  :require => 'net/ldap'
gem 'ruby-saml-mod',  '0.1.4'
gem 'rubycas-client', '2.2.1'
gem 'rubyzip',        '0.9.4',  :require => 'zip/zip'
gem 'sanitize',       '1.2.1'
gem 'uuid',           '2.3.2'
gem 'will_paginate',  '2.3.15'
gem 'xml-simple',     '1.0.12', :require => 'xmlsimple'
# this is only needed by jammit, but we're pinning at 0.9.4 because 0.9.5 breaks
gem 'yui-compressor', '0.9.4'

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
  gem 'barista',        '1.2.1'
  gem 'bluecloth',    '2.0.10' # for generating api docs
  gem 'parallel_tests', '0.6.11'
  gem 'mocha',        '0.10.0'
  gem 'rcov',         '0.9.9'
  gem 'rspec',        '1.3.2'
  gem 'rspec-instafail', '0.1.9'
  gem 'rspec-rails',  '1.3.4'
  gem 'selenium-webdriver', '2.14.0'
  gem 'webrat',       '0.7.3'
  gem 'yard',         '0.7.2'
end

group :development do
  gem 'barista',        '1.2.1'
  gem 'coffee-script-source',  '1.1.2' #pinned just so everyone's compiled output matches
  gem 'ruby-debug',   '0.10.4'
  gem 'ruby_parser', '2.0.6'
  gem 'sexp_processor', '3.0.5'
  gem 'ya2yaml', '0.30'
  gem 'guard'
  gem 'guard-coffeescript'
end

group :redis do
  gem 'redis-store', '1.0.0.rc1'
end


# The closure-compiler gem has an undocumented
# gem dependency on windows with ruby < 1.9.  I'm
# working to get this fixed in the gem itself, but
# in the mean time this needs to be here to make
# things work on windows.
WINDOWS  = RUBY_PLATFORM.match(/(win|w)32$/)
ONE_NINE = RUBY_VERSION >= "1.9"
if WINDOWS
  if !ONE_NINE
    gem 'win32-open3',  '0.3.2'
  end
end

if !ONE_NINE
  gem 'fastercsv', '1.5.3'
end

# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__),'vendor/plugins/*/Gemfile')].each do |g|
  eval(File.read(g))
end

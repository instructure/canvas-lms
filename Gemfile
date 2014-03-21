source 'https://rubygems.org/'

# this has to use 1.8.7 hash syntax to not raise a parser exception on 1.8.7
if RUBY_VERSION == "2.0.0"
  warn "Ruby 2.0 support is untested"
  ruby '2.0.0', :engine => 'ruby', :engine_version => '2.0.0'
elsif RUBY_VERSION == "2.1.0"
  warn "Ruby 2.1 support is untested"
  ruby '2.1.0', :engine => 'ruby', :engine_version => '2.1.0'
else
  ruby '1.9.3', :engine => 'ruby', :engine_version => '1.9.3'
end

# enforce the version of bundler itself, to avoid any surprises
required_bundler_version = '1.5.1'..'1.5.3'
gem 'bundler', [">=#{required_bundler_version.first}", "<=#{required_bundler_version.last}"]

unless required_bundler_version.include?(Bundler::VERSION)
  if Bundler::VERSION < required_bundler_version.first
    bundle_command = "gem install bundler -v #{required_bundler_version.last}"
  else
    require 'shellwords'
    bundle_command = "bundle _#{required_bundler_version.last}_ #{ARGV.map { |a| Shellwords.escape(a) }.join(' ')}"
  end

  warn "Bundler version #{required_bundler_version.first} is required; you're currently running #{Bundler::VERSION}. Maybe try `#{bundle_command}`."
  exit 1
end

require File.expand_path("../config/canvas_rails3", __FILE__)

# force a different lockfile for rails 3
if CANVAS_RAILS3
  Bundler::SharedHelpers.class_eval do
    class << self
      def default_lockfile
        Pathname.new("#{Bundler.default_gemfile}.lock3")
      end
    end
  end

  Bundler::Dsl.class_eval do
    def to_definition(lockfile, unlock)
      @sources << @rubygems_source unless @sources.include?(@rubygems_source)
      Definition.new(Bundler.default_lockfile, @dependencies, @sources, unlock, @ruby_version)
    end
  end
end

# patch bundler to do github over https
unless Bundler::Dsl.private_instance_methods.include?(:_old_normalize_options)
  class Bundler::Dsl
    alias_method :_old_normalize_options, :_normalize_options
    def _normalize_options(name, version, opts)
      _old_normalize_options(name, version, opts)
      opts['git'].sub!('git://', 'https://') if opts['git'] && opts['git'] =~ %r{^git://github.com}
    end
  end
end

platforms :ruby_20, :ruby_21 do
  gem 'syck', '1.0.1'
  gem 'iconv', '1.0.3'
end

if CANVAS_RAILS2
  # If you have a license to rails lts, you can create a vendor/plugins/*/RAILS_LTS yaml file
  # with the Gemfile `gem` command to use (pointing to the private repo with your username/password).
  # Otherwise, the free community version of rails lts will be used.
  lts_file = Dir.glob(File.expand_path("../vendor/plugins/*/RAILS_LTS", __FILE__)).first
  if lts_file
    eval(File.read(lts_file))
  else
    gem 'rails', :github => 'makandra/rails', :branch => '2-3-lts', :ref => 'e86daf8ff727d5efc0040c876ba00c9444a5d915'
  end
  # AMS needs to be loaded BEFORE authlogic because it defines the constant
  # "ActiveModel", and aliases ActiveRecord::Errors to ActiveModel::Errors
  # so Authlogic will use the right thing when it detects that ActiveModel
  # is defined.
  gem 'active_model_serializers_rails_2.3', '0.9.0alpha1', :require => 'active_model_serializers'
  gem 'authlogic', '2.1.3'
else
  # just to be clear, Canvas is NOT READY to run under Rails 3 in production
  gem 'rails', '3.2.17'
  gem 'active_model_serializers', '0.9.0alpha1',
    :github => 'rails-api/active_model_serializers', :ref => '61882e1e4127facfe92e49057aec71edbe981829'
  gem 'authlogic', '3.3.0'
end

if CANVAS_RAILS2
  gem 'instructure-active_model-better_errors', '1.6.5.rails2.3', :require => 'active_model/better_errors'
else
  gem 'active_model-better_errors', '1.6.7', :require => 'active_model/better_errors'
end
gem "aws-sdk", '1.21.0'
  gem 'uuidtools', '2.1.4'
gem 'barby', '0.5.0'
gem 'bcrypt-ruby', '3.0.1'
gem 'builder', '3.0.0'
gem 'canvas_connect', '0.3.2'
  gem 'adobe_connect', '1.0.0'
gem 'canvas_webex', '0.13'
gem 'daemons', '1.1.0'
gem 'diff-lcs', '1.1.3', :require => 'diff/lcs'
unless CANVAS_RAILS2
  gem 'dynamic_form', '1.1.4'
end
if CANVAS_RAILS2
  gem 'encrypted_cookie_store-instructure', '1.0.5', :require => 'encrypted_cookie_store'
else
  gem 'encrypted_cookie_store-instructure', '1.1.2', :require => 'encrypted_cookie_store'
end
if CANVAS_RAILS2
  gem 'erubis', '2.7.0'
end
if CANVAS_RAILS2
  gem 'fake_arel', '1.5.0'
  gem 'fake_rails3_routes', '1.0.4'
    gem 'journey', '1.0.4'
end
gem 'ffi', '1.1.5'
gem 'hairtrigger', '0.2.3'
  gem 'ruby2ruby', '2.0.7'
gem 'sass', '3.2.3'
gem 'hashery', '1.3.0', :require => 'hashery/dictionary'
gem 'highline', '1.6.1'
gem 'hoe', '3.8.1'
gem 'i18n', '0.6.8'
gem 'i18nema', '0.0.7'
gem 'icalendar', '1.1.5'
gem 'jammit', '0.6.6'
  gem 'cssmin', '1.0.3'
  gem 'jsmin', '1.0.1'
gem 'json', '1.8.1'
gem 'oj', '2.5.5'
unless CANVAS_RAILS2
  gem 'rails-patch-json-encode', '0.0.1'
end
# native xml parsing, diigo
gem 'libxml-ruby', '2.6.0', :require => 'xml/libxml'
gem 'macaddr', '1.0.0' # macaddr 1.2.0 tries to require 'systemu' which isn't a dependency
gem 'mail', '2.5.4'
  gem 'treetop', '1.4.15'
    gem 'polyglot', '0.3.3'
gem 'marginalia', '1.1.3', :require => false
gem 'mime-types', '1.17.2', :require => 'mime/types'
# attachment_fu (even the current technoweenie one on github) does not work
# with mini_magick 3.1
gem 'mini_magick', '1.3.2'
  gem 'subexec', '0.0.4'
gem 'multi_json', '1.8.2'
gem 'netaddr', '1.5.0'
gem 'nokogiri', '1.5.6'
# oauth gem, with rails3 fixes rolled in
gem 'oauth-instructure', '0.4.10', :require => 'oauth'
gem 'rack', CANVAS_RAILS2 ? '1.1.3' : '1.4.5'
gem 'rake', '10.1.1'
gem 'rdoc', '3.12'
gem 'ratom-instructure', '0.6.9', :require => "atom" # custom gem until necessary changes are merged into mainstream
gem 'rdiscount', '1.6.8'
gem 'ritex', '1.0.1'
unless CANVAS_RAILS2
  gem 'routing_concerns', '0.1.0'
end
gem 'rotp', '1.4.1'
gem 'rqrcode', '0.4.2'
gem 'rscribd', '1.2.0'
gem 'net-ldap', '0.3.1', :require => 'net/ldap'
gem 'ruby-saml-mod', '0.1.25'
gem 'rubycas-client', '2.2.1'
gem 'rubyzip', '1.1.0', :require => 'zip', :github => 'rubyzip/rubyzip', :ref => '2697c7ea4fba6dca66acd4793965501b06ea8df6'
gem 'zip-zip', '0.2' # needed until plugins use the new namespace
gem 'safe_yaml', '0.9.7', :require => false
gem 'safe_yaml-instructure', '0.8.0', :require => false
  gem 'hashie', '2.0.5'
gem 'sanitize', '2.0.3'
gem 'shackles', '1.0.2'
unless CANVAS_RAILS2
  gem 'switchman', '1.1.0'
end
gem 'tzinfo', '0.3.35'
gem 'useragent', '0.4.16'
gem 'uuid', '2.3.2'
if CANVAS_RAILS2
  gem 'folio-pagination-legacy', '0.0.3', :require => 'folio/rails'
  gem 'will_paginate', '2.3.15', :require => false
else
  gem 'folio-pagination', '0.0.7', :require => 'folio/rails'
  gem 'will_paginate', '3.0.4', :require => false
end
gem 'xml-simple', '1.0.12', :require => 'xmlsimple'
gem 'foreigner', '0.9.2'
gem 'crocodoc-ruby', '0.0.1', :require => 'crocodoc'

gem 'activesupport-suspend_callbacks', :path => 'gems/activesupport-suspend_callbacks'
gem 'adheres_to_policy', :path => 'gems/adheres_to_policy'
gem 'canvas_breach_mitigation', :path => 'gems/canvas_breach_mitigation'
gem 'canvas_color', :path => 'gems/canvas_color'
gem 'canvas_crummy', :path => 'gems/canvas_crummy'
gem 'canvas_mimetype_fu', :path => 'gems/canvas_mimetype_fu'
gem 'canvas_sanitize', :path => 'gems/canvas_sanitize'
gem 'canvas_statsd', :path => 'gems/canvas_statsd'
gem 'canvas_stringex', :path => 'gems/canvas_stringex'
gem 'canvas_uuid', :path => 'gems/canvas_uuid'
gem 'html_text_helper', :path => 'gems/html_text_helper'
gem 'lti_outbound', :path => 'gems/lti_outbound'
gem 'multipart', :path => 'gems/multipart'
gem 'workflow', :path => 'gems/workflow'

group :assets do
  gem 'compass-rails', '1.0.3'
    gem 'compass', '0.12.2'
      gem 'chunky_png', '1.2.9'
      gem 'fssm', '0.2.10'
  gem 'dress_code', '1.0.2'
    gem 'colored', '1.2'
    gem 'mustache', '0.99.5'
    gem 'pygments.rb', '0.5.4'
      gem 'posix-spawn', '0.3.8'
      gem 'yajl-ruby', '1.1.0'
end

group :mysql do
  gem 'mysql2', '0.2.18'
end

group :postgres do
  gem 'pg', '0.15.0'
end

group :sqlite do
  gem 'sqlite3', '1.3.8'
end

group :test do

  gem 'simplecov', '0.8.2', :require => false
    gem 'docile', '1.1.3'
  gem 'simplecov-rcov', '0.2.3', :require => false
  gem 'bluecloth', '2.0.10' # for generating api docs
    gem 'redcarpet', '3.0.0'
  gem 'mocha', '1.0.0.alpha', :require => false
    gem 'metaclass', '0.0.2'
  gem 'thin', '1.5.1'
    gem 'eventmachine', '1.0.3'
  if CANVAS_RAILS2
    gem 'rspec', '1.3.2'
    gem 'rspec-rails', '1.3.4'
  else
    gem 'rspec', '2.14.1'
    gem 'rspec-rails', '2.14.1'
  end
  gem 'sequel', '4.5.0', :require => false
  gem 'selenium-webdriver', '2.39.0'
    gem 'childprocess', '0.4.0'
    gem 'websocket', '1.0.7'
  gem 'webmock', '1.16.1', :require => false
    gem 'addressable', '2.3.5'
    gem 'crack', '0.4.1'
  gem 'yard', '0.8.0'
  gem 'yard-appendix', '>=0.1.8'
  gem 'timecop', '0.6.3'
  if CANVAS_RAILS2
    gem 'test-unit', '1.2.3'
  end
  gem 'bullet', '4.5.0', :require => false
    gem 'uniform_notifier', '1.4.0'
end

group :development do
  gem 'guard', '1.8.0'
  gem 'listen', '~>1.3' # pinned to fix guard error
  gem 'rb-inotify', '~>0.9.0', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.
  unless ENV['DISABLE_RUBY_DEBUGGING']
    gem 'byebug', '2.4.1', :platforms => [:ruby_20, :ruby_21]
    gem 'debugger', '1.5.0', :platforms => :ruby_19
  end
end

group :development, :test do
  gem 'coffee-script', '2.2.0'
  gem 'coffee-script-source', '1.6.2' #pinned so everyone's compiled output matches
  gem 'execjs', '1.4.0'
  gem 'parallel', '0.5.16'
end

group :i18n_tools do
  gem 'ruby_parser', '3.1.3'
  gem 'sexp_processor', '4.2.1'
  gem 'ya2yaml', '0.30'
end

group :redis do
  gem 'instructure-redis-store', '1.0.0.2.instructure1', :require => 'redis-store'
  gem 'redis', '3.0.1'
  gem 'redis-scripting', '1.0.1'
end

group :cassandra do
  gem 'cassandra-cql', '1.2.1', :github => 'kreynolds/cassandra-cql', :ref => 'd100be075b04153cf4116da7512892a1e8c0a7e4' #dependency of canvas_cassandra
    gem 'simple_uuid', '0.4.0'
    gem 'thrift', '0.8.0'
    gem 'thrift_client', '0.8.4'
  gem "canvas_cassandra", path: "gems/canvas_cassandra"
end

group :icu do
  gem 'ffi-icu', '0.1.2'
end

# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__), 'vendor/plugins/*/Gemfile')].each do |g|
  eval(File.read(g))
end

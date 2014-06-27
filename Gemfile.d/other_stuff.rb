if CANVAS_RAILS2
  # If you have a license to rails lts, you can create a vendor/plugins/*/RAILS_LTS yaml file
  # with the Gemfile `gem` command to use (pointing to the private repo with your username/password).
  # Otherwise, the free community version of rails lts will be used.
  lts_file = Dir.glob(File.expand_path("../../vendor/plugins/*/RAILS_LTS", __FILE__)).first
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

  gem 'instructure-active_model-better_errors', '1.6.5.rails2.3', :require => 'active_model/better_errors'
  gem 'encrypted_cookie_store-instructure', '1.0.5', :require => 'encrypted_cookie_store'
  gem 'erubis', '2.7.0'
  gem 'fake_arel', '1.5.0'
  gem 'fake_rails3_routes', '1.0.4'
    gem 'journey', '1.0.4'
  gem 'rack', '1.1.3'
  gem 'folio-pagination-legacy', '0.0.3', :require => 'folio/rails'
  gem 'will_paginate', '2.3.15', :require => false
else
  # just to be clear, Canvas is NOT READY to run under Rails 3 in production
  gem 'rails', '3.2.17'
  gem 'active_model_serializers', '0.9.0alpha1',
    :github => 'rails-api/active_model_serializers', :ref => '61882e1e4127facfe92e49057aec71edbe981829'
  gem 'authlogic', '3.3.0'
  gem 'active_model-better_errors', '1.6.7', :require => 'active_model/better_errors'
  gem 'dynamic_form', '1.1.4'
  gem 'encrypted_cookie_store-instructure', '1.1.3', :require => 'encrypted_cookie_store'
  gem 'rails-patch-json-encode', '0.0.1'
  gem 'rack', '1.4.5'
  gem 'routing_concerns', '0.1.0'
  gem 'switchman', '1.2.5'
  gem 'folio-pagination', '0.0.7', :require => 'folio/rails'
  gem 'will_paginate', '3.0.4', :require => false
end

gem "aws-sdk", '1.21.0'
  gem 'uuidtools', '2.1.4'
gem 'barby', '0.5.0'
gem 'bcrypt-ruby', '3.0.1'
gem 'builder', '3.0.0'
gem 'canvas_connect', '0.3.5'
  gem 'adobe_connect', '1.0.0'
gem 'canvas_webex', '0.14'
gem 'daemons', '1.1.0'
gem 'diff-lcs', '1.1.3', :require => 'diff/lcs'

gem 'ffi', '1.1.5'
gem 'hairtrigger', '0.2.9'
  gem 'ruby2ruby', '2.0.8'
  gem 'ruby_parser', '3.6.1'
gem 'hashery', '1.3.0', :require => 'hashery/dictionary'
gem 'highline', '1.6.1'
gem 'hoe', '3.8.1'
gem 'i18n', '0.6.8'
gem 'i18nema', RUBY_VERSION >= '2.2' ? '0.0.8' : '0.0.7'
gem 'icalendar', '1.5.4'
gem 'jammit', '0.6.6'
  gem 'cssmin', '1.0.3'
  gem 'jsmin', '1.0.1'
gem 'json', '1.8.1'
gem 'oj', '2.5.5'

# native xml parsing, diigo
gem 'libxml-ruby', '2.6.0', :require => 'xml/libxml'
gem 'macaddr', '1.0.0' # macaddr 1.2.0 tries to require 'systemu' which isn't a dependency
gem 'mail', '2.5.4'
  gem 'treetop', '1.4.15'
    gem 'polyglot', '0.3.5'
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
gem 'rack-mini-profiler', '0.9.1', :require => false
gem 'rake', '10.3.2'
gem 'rdoc', '3.12'
gem 'ratom-instructure', '0.6.9', :require => "atom" # custom gem until necessary changes are merged into mainstream
gem 'rdiscount', '1.6.8'
gem 'ritex', '1.0.1'

gem 'rotp', '1.6.1'
gem 'rqrcode', '0.4.2'
gem 'rscribd', '1.2.0'
gem 'net-ldap', '0.3.1', :require => 'net/ldap'
gem 'ruby-saml-mod', '0.1.29'
gem 'rubycas-client', '2.3.9'
gem 'rubyzip', '1.1.0', :require => 'zip', :github => 'rubyzip/rubyzip', :ref => '2697c7ea4fba6dca66acd4793965501b06ea8df6'
gem 'zip-zip', '0.2' # needed until plugins use the new namespace
gem 'safe_yaml', '0.9.7', :require => false
gem 'safe_yaml-instructure', '0.8.0', :require => false
  gem 'hashie', '2.0.5'
gem 'sanitize', '2.0.3'
gem 'shackles', '1.0.5'

gem 'tzinfo', '0.3.35'
gem 'useragent', '0.4.16'
gem 'uuid', '2.3.2'

gem 'xml-simple', '1.0.12', :require => 'xmlsimple'
gem 'foreigner', '0.9.2'
gem 'crocodoc-ruby', '0.0.1', :require => 'crocodoc'

gem 'active_polymorph', :path => 'gems/active_polymorph'
gem 'activesupport-suspend_callbacks', :path => 'gems/activesupport-suspend_callbacks'
gem 'acts_as_list', :path => 'gems/acts_as_list'
gem 'adheres_to_policy', :path => 'gems/adheres_to_policy'
gem 'bookmarked_collection', :path => 'gems/bookmarked_collection'
gem 'canvas_breach_mitigation', :path => 'gems/canvas_breach_mitigation'
gem 'canvas_color', :path => 'gems/canvas_color'
gem 'canvas_crummy', :path => 'gems/canvas_crummy'
gem 'canvas_ember_url', :path => 'gems/canvas_ember_url'
gem 'canvas_ext', :path => 'gems/canvas_ext'
gem 'canvas_http', :path => 'gems/canvas_http'
gem 'canvas_kaltura', :path => 'gems/canvas_kaltura'
gem 'event_stream', :path => 'gems/event_stream'
gem 'canvas_mimetype_fu', :path => 'gems/canvas_mimetype_fu'
gem 'canvas_quiz_statistics', :path => 'gems/canvas_quiz_statistics'
gem 'canvas_sanitize', :path => 'gems/canvas_sanitize'
gem 'canvas_sort', :path => 'gems/canvas_sort'
gem 'canvas_statsd', :path => 'gems/canvas_statsd'
gem 'canvas_stringex', :path => 'gems/canvas_stringex'
gem 'canvas_text_helper', :path => 'gems/canvas_text_helper'
gem 'canvas_time', :path => 'gems/canvas_time'
gem 'canvas_uuid', :path => 'gems/canvas_uuid'
gem 'facebook', :path => 'gems/facebook'
gem 'google_docs', :path => 'gems/google_docs'
gem 'html_text_helper', :path => 'gems/html_text_helper'
gem 'incoming_mail_processor', :path => 'gems/incoming_mail_processor'
gem 'json_token', :path => 'gems/json_token'
gem 'linked_in', :path => 'gems/linked_in'
gem 'lti_outbound', :path => 'gems/lti_outbound'
gem 'multipart', :path => 'gems/multipart'
gem 'paginated_collection', :path => 'gems/paginated_collection'
gem 'twitter', :path => 'gems/twitter'
gem 'utf8_cleaner', :path => 'gems/utf8_cleaner'
gem 'workflow', :path => 'gems/workflow'


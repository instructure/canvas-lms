
if CANVAS_RAILS3
  gem 'rails', '3.2.21', github: 'rails/rails', branch: '3-2-stable', ref: 'b344986bc3d94ca7821fc5e0eef1874882ac6cbb'
  gem 'rack', '1.4.5'
  gem 'builder', '3.0.0'
  gem 'routing_concerns', '0.1.0'
  gem 'strong_parameters', '0.2.3'
else
  gem 'rails', '4.0.12'
  gem 'rack', '1.5.2'
  gem 'builder', '3.1.4'
  gem 'protected_attributes', '1.0.8'
  gem 'rails-observers', '0.1.2'
end
gem 'tzinfo', '0.3.43'
gem 'encrypted_cookie_store-instructure', '1.1.10', require: 'encrypted_cookie_store'
gem 'active_model_serializers', '0.9.0alpha1',
  github: 'rails-api/active_model_serializers', ref: '61882e1e4127facfe92e49057aec71edbe981829'
gem 'authlogic', '3.4.2'
gem 'active_model-better_errors', '1.6.7', require: 'active_model/better_errors'
gem 'dynamic_form', '1.1.4', require: false
gem 'rails-patch-json-encode', '0.0.1'
gem 'switchman', '1.2.29'
gem 'folio-pagination', '0.0.7', require: 'folio/rails'
gem 'will_paginate', '3.0.4', require: false

gem "after_transaction_commit", '1.0.1'
gem "aws-sdk", '1.63.0', require: false
  gem 'uuidtools', '2.1.4', require: false
gem 'barby', '0.5.0', require: false
  gem 'rqrcode', '0.4.2', require: false
  gem 'chunky_png', '1.3.0', require: false
gem 'bcrypt-ruby', '3.0.1'
gem 'canvas_connect', '0.3.7'
  gem 'adobe_connect', '1.0.2', require: false
gem 'canvas_webex', '0.15'
gem 'canvas-jobs', '0.9.12'

gem 'ffi', '1.1.5', require: false
gem 'hairtrigger', '0.2.12'
  gem 'ruby2ruby', '2.0.8', require: false
  gem 'ruby_parser', '3.6.1', require: false
gem 'hashery', '1.3.0', require: false
gem 'highline', '1.6.1', require: false
gem 'hoe', '3.8.1'
gem 'i18n', '0.7.0'
gem 'i18nema', '0.0.8', platforms: [:ruby_20, :ruby_21, :ruby_22]
gem 'i18nema19', '0.0.8', platform: :ruby_19
gem 'i18nliner', '0.0.11'
gem 'icalendar', '1.5.4', require: false
gem 'ims-lti', '2.0.0.beta.18', require: false
gem 'jammit', github: 'documentcloud/jammit', ref: '98b50a67029c2860717485a72a2ff0ae8ec37840'
  gem 'cssmin', '1.0.3', require: false
  gem 'jsmin', '1.0.1', require: false
gem 'json', '1.8.2'
gem 'oj', '2.5.5'
gem 'jwt', '1.2.1', require: false

gem 'mail', '2.5.4', require: false
  gem 'treetop', '1.4.15', require: false
    gem 'polyglot', '0.3.5', require: false
gem 'marginalia', '1.3.0', require: false
gem 'mime-types', '1.17.2', require: 'mime/types'
# attachment_fu (even the current technoweenie one on github) does not work
# with mini_magick 3.1
gem 'mini_magick', '1.3.2'
  gem 'subexec', '0.0.4', require: false
gem 'multi_json', '1.10.1'
gem 'netaddr', '1.5.0', require: false
gem 'nokogiri', '1.6.6.2', require: false
# oauth gem, with rails3 fixes rolled in
gem 'oauth-instructure', '0.4.10', require: false
gem 'rack-mini-profiler', '0.9.1', require: false
gem 'rake', '10.4.2'
gem 'rdoc', '3.12'
gem 'ratom', '0.9.0', require: false
gem 'rdiscount', '1.6.8', require: false
gem 'ritex', '1.0.1', require: false

gem 'rotp', '1.6.1', require: false
gem 'net-ldap', '0.10.1', require: false
gem 'ruby-duration', '3.2.0', require: false
gem 'ruby-saml-mod', '0.2.4'
gem 'rubycas-client', '2.3.9', require: false
gem 'rubyzip', '1.1.1', require: 'zip'
gem 'zip-zip', '0.2' # needed until plugins use the new namespace
gem 'safe_yaml', '0.9.7', require: false
gem 'safe_yaml-instructure', '0.8.0', require: false
  gem 'hashie', '2.0.5', require: false
gem 'sanitize', '2.0.6', require: false
gem 'shackles', '1.0.7'

gem 'useragent', '0.10.0', require: false

gem 'foreigner', '0.9.2'
gem 'crocodoc-ruby', '0.0.1', require: false
gem 'hey', '1.3.0', require: false
gem 'aroi', '0.0.2'
gem 'sentry-raven', '0.12.3', require: false

gem 'active_polymorph', path: 'gems/active_polymorph'
gem 'activesupport-suspend_callbacks', path: 'gems/activesupport-suspend_callbacks'
gem 'acts_as_list', path: 'gems/acts_as_list'
gem 'adheres_to_policy', path: 'gems/adheres_to_policy'
gem 'attachment_fu', path: 'gems/attachment_fu'
gem 'autoextend', path: 'gems'
gem 'bookmarked_collection', path: 'gems/bookmarked_collection'
gem 'broadcast_policy', path: "gems/broadcast_policy"
gem 'canvas_breach_mitigation', path: 'gems/canvas_breach_mitigation'
gem 'canvas_color', path: 'gems/canvas_color'
gem 'canvas_crummy', path: 'gems/canvas_crummy'
gem 'canvas_ext', path: 'gems/canvas_ext'
gem 'canvas_http', path: 'gems/canvas_http'
gem 'canvas_kaltura', path: 'gems/canvas_kaltura'
gem 'canvas_panda_pub', path: 'gems/canvas_panda_pub'
gem 'canvas_partman', path: 'gems/canvas_partman'
gem 'event_stream', path: 'gems/event_stream'
gem 'canvas_mimetype_fu', path: 'gems/canvas_mimetype_fu'
gem 'canvas_quiz_statistics', path: 'gems/canvas_quiz_statistics'
gem 'canvas_sanitize', path: 'gems/canvas_sanitize'
gem 'canvas_slug', path: 'gems/canvas_slug'
gem 'canvas_sort', path: 'gems/canvas_sort'
gem 'canvas_statsd', path: 'gems/canvas_statsd'
gem 'canvas_stringex', path: 'gems/canvas_stringex'
gem 'canvas_text_helper', path: 'gems/canvas_text_helper'
gem 'canvas_time', path: 'gems/canvas_time'
gem 'canvas_unzip', path: 'gems/canvas_unzip'
gem 'csv_diff', path: 'gems/csv_diff'
gem 'google_docs', path: 'gems/google_docs'
gem 'google_drive', path: 'gems/google_drive'
gem 'html_text_helper', path: 'gems/html_text_helper'
gem 'incoming_mail_processor', path: 'gems/incoming_mail_processor'
gem 'json_token', path: 'gems/json_token'
gem 'linked_in', path: 'gems/linked_in'
gem 'live_events', path: 'gems/live_events'
gem 'diigo', path: 'gems/diigo'
gem 'lti_outbound', path: 'gems/lti_outbound'
gem 'multipart', path: 'gems/multipart'
gem 'paginated_collection', path: 'gems/paginated_collection'
gem 'twitter', path: 'gems/twitter'
gem 'utf8_cleaner', path: 'gems/utf8_cleaner'
gem 'workflow', path: 'gems/workflow'

if CANVAS_RAILS4_2
  gem 'rails', '4.2.7.1'
  gem 'rack', '1.6.4'
  gem 'protected_attributes', '1.1.3'
  gem 'rails-observers', '0.1.2'
  gem 'activesupport-json_encoder', '1.1.0'
  gem 'oauth2', '1.0.0', require: false
else
  gem 'rails', '5.0.0.1'
  gem 'rails-observers', github: 'rails/rails-observers', ref: '3fe157d6cbb5b5e767ded248009fc59443d63fa1'
  gem 'rack', '2.0.1'
  gem 'oauth2', '1.2.0', require: false
end

gem 'builder', '3.2.2'
gem 'tzinfo', '1.2.2'
gem 'oj_mimic_json', require: false

gem 'encrypted_cookie_store-instructure', '1.2.2', require: 'encrypted_cookie_store'
gem 'active_model_serializers',   '0.9.0alpha1',
  github: 'rails-api/active_model_serializers', ref: '61882e1e4127facfe92e49057aec71edbe981829'
gem 'authlogic', '3.5.0'
  gem 'scrypt', '3.0.3'
gem 'active_model-better_errors', '1.6.7', require: 'active_model/better_errors'
gem 'dynamic_form', '1.1.4', require: false
gem 'rails-patch-json-encode', '0.0.1'
gem 'switchman', '1.9.2'
  gem 'open4', '1.3.4', require: false
gem 'folio-pagination', '0.0.11', require: 'folio/rails'
  # for folio, see the folio README
  gem 'will_paginate', '3.1.5', require: false

gem "after_transaction_commit", '1.1.0'
gem "aws-sdk", '2.6.7', require: false
gem "aws-sdk-v1", '1.66.0', require: false
gem 'barby', '0.6.5', require: false
  gem 'rqrcode', '0.10.1', require: false
  gem 'chunky_png', '1.3.8', require: false
gem 'bcrypt', '3.1.11'
gem 'canvas_connect', '0.3.10'
  gem 'adobe_connect', '1.0.4', require: false
gem 'canvas_webex', '0.17'
gem 'inst-jobs', '0.11.6'
  gem 'rufus-scheduler', '3.2.2', require: false
gem 'ffi', '1.9.14', require: false
gem 'hairtrigger', '0.2.17'
  gem 'ruby2ruby', '2.0.8', require: false
  gem 'ruby_parser', '3.8.3', require: false
gem 'hashery', '2.1.2', require: false
gem 'highline', '1.7.8', require: false
gem 'httparty', '0.14.0'
gem 'i18n', '0.7.0'
gem 'i18nliner', '0.0.12'
gem 'icalendar', '1.5.4', require: false
gem 'ims-lti', '2.1.0.beta.3', require: 'ims'
gem 'json', '1.8.3'
gem 'oj', '2.17.1'
gem 'jwt', '1.2.1', require: false
gem 'json-jwt', '1.6.5', require: false
gem 'twilio-ruby', '4.2.1'

gem 'mail', '2.5.4', require: false
  gem 'treetop', '1.4.15', require: false
    gem 'polyglot', '0.3.5', require: false
gem 'marginalia', '1.4.0', require: false
gem 'mime-types', '1.25.1', require: 'mime/types'
gem 'mini_magick', '4.2.7'
gem 'multi_json', '1.12.1'
gem 'netaddr', '1.5.1', require: false
gem 'nokogiri', '1.6.6.2.20150813143452', require: false, github: 'codekitchen/nokogiri', ref: 'd47e53f885'
# oauth gem, with rails3 fixes rolled in
gem 'oauth-instructure', '0.4.10', require: false
gem 'parallel', '1.10.0', require: false
  gem 'ruby-progressbar', '1.8.1', require: false #used to show progress of S3Uploader
gem 'retriable', '1.4.1'
gem 'rake', '12.0.0'
gem 'ratom-nokogiri', '0.10.4', require: false
gem 'rdiscount', '1.6.8', require: false
gem 'ritex', '1.0.1', require: false

gem 'rotp', '3.3.0', require: false
gem 'net-ldap', '0.10.1', require: false
gem 'ruby-duration', '3.2.3', require: false
gem 'ruby-saml-mod', '0.3.1'
gem 'saml2', '1.0.7', require: false
  gem 'nokogiri-xmlsec-me-harder', '0.9.3pre', require: false, github: 'instructure/nokogiri-xmlsec-me-harder', ref: '57d071040cc4649db9f158e09bbcea028271a4a6'
gem 'rubycas-client', '2.3.9', require: false
gem 'rubyzip', '1.2.0', require: 'zip'
gem 'safe_yaml', '1.0.4', require: false
gem 'sanitize', '2.1.0', require: false
gem 'shackles', '1.3.0'

gem 'useragent', '0.16.8', require: false

gem 'crocodoc-ruby', '0.0.1', require: false
gem 'hey', '1.3.0', require: false
gem 'sentry-raven', '0.15.6', require: false
gem 'canvas_statsd', '1.0.8'
  gem 'statsd-ruby', '1.3.0', require: false
  gem 'aroi', '0.0.4', require: false
gem 'diplomat', '1.0.0', require: false
gem 'gepub'
gem 'academic_benchmarks', '0.0.8', require: false

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
gem 'canvas_stringex', path: 'gems/canvas_stringex'
gem 'canvas_text_helper', path: 'gems/canvas_text_helper'
gem 'canvas_time', path: 'gems/canvas_time'
gem 'canvas_unzip', path: 'gems/canvas_unzip'
gem 'csv_diff', path: 'gems/csv_diff'
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
gem 'stringify_ids', path: 'gems/stringify_ids'
gem 'twitter', path: 'gems/twitter'
gem 'vericite_api', '1.2.0'
gem 'utf8_cleaner', path: 'gems/utf8_cleaner'
gem 'workflow', path: 'gems/workflow'

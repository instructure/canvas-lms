#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

if CANVAS_RAILS5_0
  gem 'rails', '5.0.4'
else
  gem 'rails', '5.1.3'
end

gem 'rack', '2.0.3'
gem 'oauth2', '1.2.0', require: false

gem 'rails-observers', '0.1.5'

gem 'builder', '3.2.3'
gem 'tzinfo', '1.2.3'

gem 'encrypted_cookie_store-instructure', '1.2.6', require: 'encrypted_cookie_store'
gem 'active_model_serializers',   '0.9.0alpha1',
  github: 'rails-api/active_model_serializers', ref: '61882e1e4127facfe92e49057aec71edbe981829'
gem 'authlogic', '3.6.0'
  gem 'scrypt', '3.0.5'
gem 'active_model-better_errors', '1.6.7', require: 'active_model/better_errors'
gem 'dynamic_form', '1.1.4', require: false
gem 'rails-patch-json-encode', '0.0.1'
gem 'switchman', '1.11.2'
  gem 'open4', '1.3.4', require: false
gem 'switchman-inst-jobs', '1.1.1'
gem 'folio-pagination', '0.0.12', require: 'folio/rails'
  # for folio, see the folio README
  gem 'will_paginate', '3.1.6', require: false

gem 'addressable', '2.5.1', require: false
gem "after_transaction_commit", '2.0.0'
gem "aws-sdk-kinesis", '1.0.0.rc9', require: false
gem "aws-sdk-s3", '1.0.0.rc13', require: false
gem "aws-sdk-sns", '1.0.0.rc9', require: false
gem "aws-sdk-sqs", '1.0.0.rc11', require: false
gem 'barby', '0.6.5', require: false
  gem 'rqrcode', '0.10.1', require: false
  gem 'chunky_png', '1.3.8', require: false
gem 'bcrypt', '3.1.11'
gem 'canvas_connect', '0.3.11'
  gem 'adobe_connect', '1.0.6', require: false
gem 'canvas_webex', '0.17'
gem 'inst-jobs', '0.13.5'
  gem 'rufus-scheduler', '3.4.2', require: false
    gem 'et-orbi', '1.0.5', require: false
gem 'ffi', '1.9.18', require: false
gem 'hashery', '2.1.2', require: false
gem 'highline', '1.7.8', require: false
gem 'httparty', '0.15.6'
gem 'i18n', '0.8.6'
gem 'i18nliner', '0.0.13'
  gem 'ruby2ruby', '2.3.1', require: false
  gem 'ruby_parser', '3.9.0', require: false
gem 'icalendar', '1.5.4', require: false
gem 'ims-lti', '2.2.1', require: 'ims'
gem 'json', '2.1.0'
gem 'oj', '3.3.2'
gem 'jwt', '1.5.6', require: false
gem 'json-jwt', '1.7.2', require: false
gem 'twilio-ruby', '4.2.1'

gem 'mail', '2.6.6', require: false
gem 'marginalia', '1.4.0', require: false
gem 'mime-types', '1.25.1', require: 'mime/types'
gem 'mini_magick', '4.8.0'
gem 'multi_json', '1.12.1'
gem 'netaddr', '1.5.1', require: false
gem 'nokogiri', '1.8.0', require: false
gem 'oauth', '0.5.3', require: false
gem 'parallel', '1.12.0', require: false
  gem 'ruby-progressbar', '1.8.1', require: false #used to show progress of S3Uploader
gem 'retriable', '1.4.1'
gem 'rake', '12.0.0'
gem 'ratom-nokogiri', '0.10.6', require: false
gem 'rdiscount', '1.6.8', require: false
gem 'ritex', '1.0.1', require: false

gem 'rotp', '3.3.0', require: false
gem 'net-ldap', '0.16.0', require: false
gem 'ruby-duration', '3.2.3', require: false
gem 'ruby-saml-mod', '0.3.6'
gem 'saml2', '1.1.3', require: false
  gem 'nokogiri-xmlsec-me-harder', '0.9.3pre', require: false, github: 'instructure/nokogiri-xmlsec-me-harder', ref: '57d071040cc4649db9f158e09bbcea028271a4a6'
gem 'rubycas-client', '2.3.9', require: false
gem 'rubyzip', '1.2.0', require: 'zip'
gem 'safe_yaml', '1.0.4', require: false
gem 'sanitize', '2.1.0', require: false
gem 'shackles', '1.4.0'

gem 'useragent', '0.16.8', require: false

gem 'crocodoc-ruby', '0.0.1', require: false
gem 'hey', '1.3.1', require: false
gem 'sentry-raven', '0.15.6', require: false
gem 'canvas_statsd', '2.0.4'
  gem 'statsd-ruby', '1.4.0', require: false
  gem 'aroi', '0.0.5', require: false
gem 'gepub', '0.7.0beta4'
gem 'imperium', '0.1.3', require: false
gem 'academic_benchmarks', '0.0.10', require: false

gem 'graphql', '1.6.6'
gem 'graphql-batch', '~>0.3.1'

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
gem 'vericite_api', '1.5.1'
gem 'utf8_cleaner', path: 'gems/utf8_cleaner'
gem 'workflow', path: 'gems/workflow'

# StrongMind
gem 'canvas_shim', :path => 'vendor/canvas_shim'
gem 'pipeline_publisher_ruby', :path => 'vendor/pipeline-publisher-ruby'
gem 'airbrake', '~> 7.2'
gem 'aws-sdk-dynamodb', '~> 1.6'
gem 'grape', '~> 1'
gem 'grape-swagger', '~> 0'
gem 'grape', '~> 1'
gem 'grape-swagger', '~> 0'
gem 'grape-swagger-rails'

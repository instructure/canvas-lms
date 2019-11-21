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

if CANVAS_RAILS5_2
  gem 'rails', '5.2.3'
    gem 'loofah', '2.3.0'
    gem 'sprockets', '3.7.2' # 4.0 requires ruby 2.5
else
  gem 'rails', '6.0.0'
end

gem 'rack', '2.0.7'

gem 'oauth2', '1.4.2', require: false

gem 'rails-observers', '0.1.5'

gem 'builder', '3.2.3'
gem 'tzinfo', '1.2.5'

gem 'encrypted_cookie_store-instructure', '1.2.9', require: 'encrypted_cookie_store'
gem 'active_model_serializers', '0.9.0alpha1',
  github: 'rails-api/active_model_serializers', ref: '61882e1e4127facfe92e49057aec71edbe981829'
gem 'authlogic', '5.0.4'
  gem 'scrypt', '3.0.6'
gem 'active_model-better_errors', '1.6.7', require: 'active_model/better_errors'
gem 'switchman', '1.14.7'
  gem 'open4', '1.3.4', require: false
gem 'folio-pagination', '0.0.12', require: 'folio/rails'
  # for folio, see the folio README
  gem 'will_paginate', '3.1.7', require: false

gem 'addressable', '2.7.0', require: false
gem "after_transaction_commit", '2.0.0'
gem "aws-sdk-dynamodb", "1.36.0"
gem "aws-sdk-kinesis", '1.19.0', require: false
gem "aws-sdk-s3", '1.48.0', require: false
gem "aws-sdk-sns", '1.19.0', require: false
gem "aws-sdk-sqs", '1.22.0', require: false
gem "aws-sdk-core", "3.68.1", require: false
  gem "aws-partitions", "1.238.0", require: false # pinning transient dependency
gem "aws-sdk-kms", "1.24.0", require: false
gem "aws-sigv4", "1.1.0", require: false

gem 'barby', '0.6.8', require: false
  gem 'rqrcode', '1.1.1', require: false
  gem 'chunky_png', '1.3.11', require: false
gem 'bcrypt', '3.1.13'
gem 'brotli', '0.2.3', require: false
gem 'canvas_connect', '0.3.11'
  gem 'adobe_connect', '1.0.8', require: false
gem 'canvas_webex', '0.17'
gem 'inst-jobs', '0.15.14'
  gem 'fugit', '1.3.3', require: false
    gem 'et-orbi', '1.2.2', require: false
gem 'switchman-inst-jobs', '1.3.6'
gem 'inst-jobs-autoscaling', '1.0.5'
  gem 'aws-sdk-autoscaling', '1.28.0', require: false
gem 'ffi', '1.11.1', require: false
gem 'hashery', '2.1.2', require: false
gem 'highline', '2.0.2', require: false
gem 'httparty', '0.17.1'
gem 'i18n', '1.0.0'
gem 'i18nliner', '0.1.1'
  gem 'ruby2ruby', '2.4.4', require: false
  gem 'ruby_parser', '3.14.0', require: false
gem 'icalendar', '2.5.3', require: false
gem 'ims-lti', '2.3.0', require: 'ims'
gem 'json_schemer', '0.2.7'
gem 'simple_oauth', '0.3.1', require: false
gem 'json', '2.2.0'
gem 'link_header', '0.0.8'
gem 'oj', '3.3.9'
gem 'json-jwt', '1.10.2', require: false
gem 'twilio-ruby', '5.27.1', require: false

gem 'mail', '2.7.1', require: false
  gem 'mini_mime', '1.0.2', require: false
gem 'marginalia', '1.8.0', require: false
gem 'mime-types', '3.3.0'
gem 'mini_magick', '4.9.5'
gem 'multi_json', '1.13.1'
gem 'nokogiri', '1.10.4', require: false
gem 'oauth', '0.5.4', require: false
gem 'parallel', '1.18.0', require: false
  gem 'ruby-progressbar', '1.10.1', require: false # used to show progress of S3Uploader
gem 'retriable', '1.4.1'
gem 'rake', '12.3.1'
gem 'ratom-nokogiri', '0.10.8', require: false
gem 'rdiscount', '1.6.8', require: false
gem 'ritex', '1.0.1', require: false

gem 'rotp', '5.1.0', require: false
gem 'net-ldap', '0.16.1', require: false
gem 'ruby-duration', '3.2.3', require: false
gem 'saml2', '3.0.8'
  gem 'nokogiri-xmlsec-instructure', '0.9.6', require: false
gem 'rubycas-client', '2.3.9', require: false
gem 'rubyzip', '1.2.2', require: 'zip'
gem 'safe_yaml', '1.0.5', require: false
gem 'sanitize', '2.1.1', require: false
gem 'shackles', '1.4.2'

gem 'browser', '2.6.1', require: false

gem 'crocodoc-ruby', '0.0.1', require: false
gem 'sentry-raven', '2.11.3', require: false
gem 'inst_statsd', '2.1.6'
  gem 'statsd-ruby', '1.4.0', require: false
  gem 'aroi', '0.0.7', require: false
  gem 'dogstatsd-ruby', '4.5.0'
gem 'inst-jobs-statsd', '1.2.3'
gem 'gepub', '1.0.4'
gem 'imperium', '0.5.1', require: false
gem 'academic_benchmarks', '0.0.11', require: false

gem 'graphql', '1.9.11'
gem 'graphql-batch', '0.4.1'

gem 'prawn-rails', '1.3.0'

gem 'redcarpet', '3.5.0', require: false

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
gem "canvas_dynamodb", path: "gems/canvas_dynamodb"
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
gem 'lti-advantage', path: 'gems/lti-advantage'
gem 'lti_outbound', path: 'gems/lti_outbound'
gem 'multipart', path: 'gems/multipart'
gem 'paginated_collection', path: 'gems/paginated_collection'
gem 'stringify_ids', path: 'gems/stringify_ids'
gem 'twitter', path: 'gems/twitter'
gem 'vericite_api', '1.5.3'
gem 'utf8_cleaner', path: 'gems/utf8_cleaner'
gem 'workflow', path: 'gems/workflow'

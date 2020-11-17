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

# Note: Indented gems are meant to indicate transient dependencies of parent gems

if CANVAS_RAILS5_2
  gem 'rails', '5.2.4.4'
    gem 'loofah', '2.3.0'
    gem 'sprockets', '4.0.2'
else
  gem 'rails', '6.0.3.4'
end

gem 'academic_benchmarks', '0.0.11', require: false
gem 'active_model-better_errors', '1.6.7', require: 'active_model/better_errors'
gem 'active_model_serializers', '0.9.0alpha1',
  github: 'rails-api/active_model_serializers', ref: '61882e1e4127facfe92e49057aec71edbe981829'
gem 'addressable', '2.7.0', require: false
gem 'after_transaction_commit', '2.2.1'
gem 'authlogic', '5.0.4'
  gem 'scrypt', '3.0.7'
gem 'aws-sdk-core', '3.109.2', require: false
  gem 'aws-partitions', '1.393.0', require: false
gem 'aws-sdk-dynamodb', '1.57.0'
gem 'aws-sdk-kinesis', '1.30.0', require: false
gem 'aws-sdk-s3', '1.84.1', require: false
gem 'aws-sdk-sns', '1.36.0', require: false
gem 'aws-sdk-sqs', '1.34.0', require: false
gem 'aws-sdk-kms', '1.39.0', require: false
gem 'aws-sigv4', '1.2.2', require: false
gem 'barby', '0.6.8', require: false
  gem 'rqrcode', '1.1.2', require: false
  gem 'chunky_png', '1.3.14', require: false
gem 'bcrypt', '3.1.16'
gem 'brotli', '0.2.3', require: false
gem 'browser', '5.1.0', require: false
gem 'builder', '3.2.4'
gem 'canvas_connect', '0.3.11'
  gem 'adobe_connect', '1.0.8', require: false
gem 'canvas_webex', '0.17'
gem 'crocodoc-ruby', '0.0.1', require: false
gem 'ddtrace', '0.33.1', require: false
gem 'encrypted_cookie_store-instructure', '1.2.10', require: 'encrypted_cookie_store'
gem 'folio-pagination', '0.0.12', require: 'folio/rails'
gem 'ffi', '1.13.1', require: false
gem 'gepub', '1.0.11', github: 'skoji/gepub', ref: '04c8c2542f9fa3f8d99652f9058d77c8a23c1fd9'
gem 'graphql', '1.9.17'
gem 'graphql-batch', '0.4.3'
gem 'hashery', '2.1.2', require: false
gem 'highline', '2.0.3', require: false
gem 'httparty', '0.18.1'
gem 'i18n', '1.8.5'
gem 'i18nliner', '0.1.2'
  gem 'ruby2ruby', '2.4.4', require: false
  gem 'ruby_parser', '3.14.2', require: false
gem 'icalendar', '2.7.0', require: false
gem 'imperium', '0.5.2', require: false
gem 'ims-lti', '2.3.0', require: 'ims'
gem 'inst_statsd', '2.1.6'
  gem 'statsd-ruby', '1.4.0', require: false
  gem 'aroi', '0.0.7', require: false
  gem 'dogstatsd-ruby', '4.7.0'
gem 'inst-jobs', '1.0.3'
  gem 'fugit', '1.3.3', require: false
    gem 'et-orbi', '1.2.4', require: false
gem 'inst-jobs-autoscaling', '2.0.0'
  gem 'aws-sdk-autoscaling', '1.49.0', require: false
gem 'inst-jobs-statsd', '2.0.0'
gem 'json', '2.3.1'
gem 'json_schemer', '0.2.16'
gem 'json-jwt', '1.13.0', require: false
gem 'link_header', '0.0.8'
gem 'mail', '2.7.1', require: false
  gem 'mini_mime', '1.0.2', require: false
gem 'marginalia', '1.9.0', require: false
gem 'mime-types', '3.3.1'
gem 'mini_magick', '4.11.0'
gem 'multi_json', '1.15.0'
gem 'net-ldap', '0.16.3', require: false
gem 'nokogiri', '1.10.10', require: false
gem 'oauth', '0.5.4', require: false
gem 'oauth2', '1.4.4', require: false
gem 'oj', '3.10.16'
gem 'parallel', '1.19.1', require: false
  gem 'ruby-progressbar', '1.10.1', require: false # used to show progress of S3Uploader
gem 'prawn-rails', '1.3.0'
gem 'rack', '2.2.3'
gem 'rack-brotli', '1.0.0'
gem 'rack-test', '1.1.0'
gem 'rake', '13.0.1'
gem 'rails-observers', '0.1.5'
gem 'ratom-nokogiri', '0.10.8', require: false
gem 'redcarpet', '3.5.0', require: false
gem 'retriable', '1.4.1'
gem 'ritex', '1.0.1', require: false
gem 'rotp', '5.1.0', require: false
gem 'ruby-duration', '3.2.3', require: false
gem 'rubycas-client', '2.3.9', require: false
gem 'rubyzip', '2.3.0', require: 'zip'
gem 'safe_yaml', '1.0.5', require: false
gem 'saml2', '3.0.9'
  gem 'nokogiri-xmlsec-instructure', '0.9.7', require: false
gem 'sanitize', '2.1.1', require: false
gem 'sentry-raven', '2.13.0', require: false
gem 'guardrail', '2.0.1'
gem 'simple_oauth', '0.3.1', require: false
gem 'switchman', '2.0.2'
  gem 'open4', '1.3.4', require: false
gem 'switchman-inst-jobs', '3.0.3'
gem 'twilio-ruby', '5.36.0', require: false
gem 'tzinfo', '1.2.7'
gem 'vault', '0.13.0', require: false
gem 'vericite_api', '1.5.3'
gem 'will_paginate', '3.3.0', require: false # required for folio-pagination

path 'gems' do
  gem 'activesupport-suspend_callbacks'
  gem 'acts_as_list'
  gem 'adheres_to_policy'
  gem 'attachment_fu'
  gem 'autoextend'
  gem 'bookmarked_collection'
  gem 'broadcast_policy'
  gem 'canvas_breach_mitigation'
  gem 'canvas_color'
  gem 'canvas_crummy'
  gem 'canvas_dynamodb'
  gem 'canvas_ext'
  gem 'canvas_http'
  gem 'canvas_kaltura'
  gem 'canvas_panda_pub'
  gem 'canvas_partman'
  gem 'canvas_mimetype_fu'
  gem 'canvas_quiz_statistics'
  gem 'canvas_sanitize'
  gem 'canvas_slug'
  gem 'canvas_sort'
  gem 'canvas_stringex'
  gem 'canvas_text_helper'
  gem 'canvas_time'
  gem 'canvas_unzip'
  gem 'diigo'
  gem 'event_stream'
  gem 'google_drive'
  gem 'html_text_helper'
  gem 'incoming_mail_processor'
  gem 'json_token'
  gem 'linked_in'
  gem 'live_events'
  gem 'lti-advantage'
  gem 'lti_outbound'
  gem 'multipart'
  gem 'paginated_collection'
  gem 'stringify_ids'
  gem 'twitter'
  gem 'utf8_cleaner'
  gem 'workflow'
end

gem 'csv_diff', path: 'gems'
  gem 'sqlite3', '1.4.2'

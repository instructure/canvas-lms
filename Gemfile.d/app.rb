# frozen_string_literal: true

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

# NOTE: Indented gems are meant to indicate optional dependencies of parent gems

gem "bootsnap", "1.13.0", require: false
gem "rails", "~> 7.0.4"
gem "tzinfo", "2.0.4"
gem "switchman", "~> 3.5"
gem "guardrail", "3.0.2"
gem "switchman-inst-jobs", "4.0.13"
gem "irb", "1.4.1"

gem "academic_benchmarks", "1.1.2", require: false
gem "active_model-better_errors", "1.6.7", require: "active_model/better_errors"
gem "active_model_serializers",
    "0.9.0alpha1",
    github: "rails-api/active_model_serializers",
    ref: "61882e1e4127facfe92e49057aec71edbe981829"
gem "activerecord-pg-extensions", "0.4.4"
gem "addressable", "~> 2.8", require: false
gem "after_transaction_commit", "2.2.2"
gem "authlogic", "6.4.2"
  gem "scrypt", "3.0.7"
gem "aws-sdk-dynamodb", "~> 1.83"
gem "aws-sdk-kinesis", "~> 1.45", require: false
gem "aws-sdk-kms", "~> 1.63", require: false
gem "aws-sdk-s3", "~> 1.119", require: false
gem "aws-sdk-sns", "~> 1.60", require: false
gem "aws-sdk-sqs", "~> 1.53", require: false
gem "barby", "0.6.8", require: false
  gem "rqrcode", "1.2.0", require: false
  gem "chunky_png", "1.4.0", require: false
gem "bcrypt", "3.1.16"
gem "bigdecimal", "3.1.3"
gem "browser", "5.1.0", require: false
gem "builder", "3.2.4"
gem "business_time", "0.13.0"
gem "canvas_connect", "0.3.16"
gem "canvas_webex", "0.18.2"
gem "crocodoc-ruby", "0.0.1", require: false
gem "ddtrace", "0.42.0", require: false
gem "docx", "0.6.2"
gem "encrypted_cookie_store-instructure", "1.2.12", require: "encrypted_cookie_store"
gem "folio-pagination", "0.0.12", require: "folio/rails"
gem "ffi", "1.14.2", require: false
gem "gepub", "1.0.15"
gem "apollo-federation", "1.1.5"
gem "graphql", "1.12.14"
gem "graphql-batch", "0.4.3"
gem "hashery", "2.1.2", require: false
gem "highline", "2.0.3", require: false
gem "httparty", "~> 0.21"
gem "i18n", "~> 1.12"
gem "i18nliner", "0.2.2", github: "instructure/i18nliner", ref: "ruby3"
gem "icalendar", "2.7.0", require: false
gem "diplomat", "2.6.3", require: false
gem "ims-lti", "2.3.3", require: "ims"
gem "rrule", "0.4.4", require: false

gem "inst_access", "0.1.1"
gem "inst_statsd", "2.2.0"
gem "inst-jobs", "~> 3.1"
gem "inst-jobs-autoscaling", "2.1.1"
gem "inst-jobs-statsd", "2.2.0"
# if updating json gem it will need to be hotfixed because if a newer version of
# the json gem is installed, it will always use that one even before bundler
# gets activated. Updating the gem in it's own commit will make this easier.
gem "json", "~> 2.6.1"
gem "json_schemer", "~> 0.2"
gem "json-jwt", "1.13.0", require: false
gem "link_header", "0.0.8"
gem "mail", "2.7.1", require: false
gem "marginalia", "1.11.1", require: false
gem "mime-types", "3.3.1"
gem "mini_magick", "4.11.0"
gem "multi_json", "1.15.0"
gem "net-ldap", "0.16.3", require: false
gem "net-imap", "0.2.3", require: false
gem "net-pop", "0.1.1", require: false
gem "net-smtp", "0.3.1", require: false
gem "nokogiri", "1.13.8", require: false
gem "oauth", "0.5.4", require: false
gem "oauth2", "1.4.4", require: false
gem "oj", "3.10.16"
gem "outrigger", "3.0.1"
gem "parallel", "1.22.1", require: false
gem "pdf-reader", "2.5.0"
gem "pg_query", "2.2.0"
gem "prawn-emoji", "~> 5.3", require: false
gem "prawn-rails", "1.3.0"
  gem "matrix", "0.4.2" # Used to be a default gem but is no more, but prawn depends on it implicitly
gem "prosopite", "~> 1.3"
gem "rack", "~> 2.2"
gem "rack-brotli", "1.0.0"
gem "rack-test", "1.1.0"
gem "rake", "~> 13.0"
gem "rails-observers", "0.1.5"
gem "ratom-nokogiri", "0.10.11", require: false
gem "redcarpet", "3.5.0", require: false
gem "regexp_parser", "2.7.0", require: false
gem "retriable", "1.4.1"
gem "ritex", "1.0.1", require: false
gem "rotp", "6.2.0", require: false
gem "rss", "0.2.9", require: false
gem "ruby-duration", "3.2.3", require: false
gem "ruby2_keywords", "0.0.3"
gem "rubycas-client", "2.3.9", require: false
gem "ruby-rtf", "0.0.5"
gem "rubyzip", "2.3.0", require: "zip"
gem "saml2", "3.1.2"
gem "sanitize", "6.0.0", require: false
gem "sentry-ruby", "5.1.0"
gem "sentry-rails", "5.1.0"
gem "sentry-inst_jobs", "1.0.2"
gem "simple_oauth", "0.3.1", require: false
gem "twilio-ruby", "5.36.0", require: false
gem "vault", "0.15.0", require: false
gem "vericite_api", "1.5.3"
gem "wcag_color_contrast", "0.1.0"
gem "week_of_month",
    "1.2.5",
    github: "instructure/week-of-month",
    ref: "b3013639e9474f302b5a6f27e4e45313e8d24902"
gem "will_paginate", "3.3.0", require: false # required for folio-pagination

gem "faraday", "0.17.4"

path "gems" do
  gem "activesupport-suspend_callbacks"
  gem "acts_as_list"
  gem "adheres_to_policy"
  gem "attachment_fu"
  gem "autoextend"
  gem "bookmarked_collection"
  gem "broadcast_policy"
  gem "canvas_breach_mitigation"
  gem "canvas_cache"
  gem "canvas_color"
  gem "canvas_crummy"
  gem "canvas_dynamodb"
  gem "canvas_errors"
  gem "canvas_ext"
  gem "canvas_http"
  gem "canvas_kaltura"
  gem "canvas_panda_pub"
  gem "canvas_partman"
  gem "canvas_mimetype_fu"
  gem "canvas_quiz_statistics"
  gem "canvas_sanitize"
  gem "canvas_security"
  gem "canvas_slug"
  gem "canvas_sort"
  gem "canvas_stringex"
  gem "canvas_text_helper"
  gem "canvas_time"
  gem "canvas_unzip"
  gem "config_file"
  gem "csv_diff"
  gem "diigo"
  gem "dynamic_settings"
  gem "event_stream"
  gem "google_drive"
  gem "html_text_helper"
  gem "incoming_mail_processor"
  gem "json_token"
  gem "linked_in"
  gem "live_events"
  gem "lti-advantage"
  gem "lti_outbound"
  gem "multipart"
  gem "paginated_collection"
  gem "request_context"
  gem "stringify_ids"
  gem "turnitin_api"
  gem "twitter"
  gem "utf8_cleaner"
  gem "workflow"
end

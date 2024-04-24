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

gem "bootsnap", "~> 1.16", require: false
gem "rails", ($canvas_rails == "7.1") ? "~> 7.1.3" : "~> 7.0.4"
  gem "rack", "~> 3.0" if $canvas_rails == "7.1" # needed to force Rack 3 due to a confluence of dependencies involving pact
gem "switchman", "~> 3.5"
gem "guardrail", "~> 3.0"
gem "switchman-inst-jobs", "~> 4.0"
gem "irb", "~> 1.7"

gem "academic_benchmarks", "~> 1.1", require: false
gem "active_model-better_errors", "1.6.7", require: "active_model/better_errors"
gem "active_model_serializers", "~> 0.9.9"
gem "addressable", "~> 2.8", require: false
gem "authlogic", "~> 6.4"
  gem "scrypt", "~> 3.0"
gem "aws-sdk-kinesis", "~> 1.45", require: false
gem "aws-sdk-s3", "~> 1.119", require: false
gem "aws-sdk-sns", "~> 1.60", require: false
gem "aws-sdk-sqs", "~> 1.53", require: false
gem "rqrcode", "~> 2.2", require: false
gem "bcrypt", "~> 3.1"
gem "bigdecimal", "~> 3.1"
gem "browser", "~> 5.3", require: false
gem "business_time", "0.13.0"
gem "canvas_connect", "0.3.16"
gem "canvas_link_migrator", "~> 1.0.8"
gem "canvas_webex", "0.18.2"
gem "crocodoc-ruby", "0.0.1", require: false
gem "code_ownership", "~> 1.33"
gem "ddtrace", "~> 1.13", require: false
gem "docx", "~> 0.8"
gem "encrypted_cookie_store-instructure", "~> 1.2", require: "encrypted_cookie_store"
gem "gepub", "1.0.15"
gem "apollo-federation", "~> 3.8"
gem "graphql", "~> 1.12.7"
gem "graphql-batch", "~> 0.5"
gem "highline", "~> 3.0", require: false
gem "httparty", "~> 0.21"
gem "i18nliner", "~> 0.2.4"
gem "icalendar", "~> 2.9", require: false
gem "diplomat", "~> 2.6", require: false
gem "ims-lti", "~> 2.3", require: "ims"
gem "rrule", "~> 0.5", require: false

gem "inst_access", "0.4.2"
gem "inst_statsd", "~> 3.0"
gem "inst-jobs", "~> 3.1"
gem "inst-jobs-autoscaling", "2.1.1"
gem "inst-jobs-statsd", "~> 3.0"
gem "json_schemer", "~> 2.0"
gem "json-jwt", "~> 1.13", require: false
gem "link_header", "0.0.8"
gem "marginalia", "1.11.1", require: false
gem "mime-types", "~> 3.5"
gem "mini_magick", "~> 4.12"
gem "multi_json", "1.15.0"
gem "neighbor", "~> 0.3"
gem "net-http", "~> 0.1", require: false
gem "net-ldap", "~> 0.18", require: false
gem "oauth", "~> 1.1", require: false
gem "oauth2", "~> 2.0", require: false
gem "oj", "~> 3.16"
gem "outrigger", "~> 3.0"
gem "parallel", "~> 1.23", require: false
gem "pdf-reader", "~> 2.11"
gem "pg_query", "~> 5.1", require: false
gem "prawn-emoji", "~> 5.3", require: false
gem "prawn-rails", "~> 1.4"
  gem "matrix", "0.4.2" # Used to be a default gem but is no more, but prawn depends on it implicitly
gem "prosopite", "~> 1.3"
if $canvas_rails == "7.1"
  gem "rack3-brotli", "~> 1.0", require: "rack/brotli"
else
  gem "rack-brotli", "~> 1.2"
end
gem "rails-observers", "0.1.5"
gem "feedjira", "~> 3.2.3", require: false
gem "redcarpet", "~> 3.6", require: false
gem "retriable", "~> 3.1"
gem "ritex", "1.0.1", require: false
gem "rotp", "~> 6.2", require: false
gem "rss", "~> 0.3", require: false
gem "ruby-duration", "3.2.3", require: false
gem "rubycas-client", "2.3.9", require: false
gem "ruby-rtf", "0.0.5"
gem "rubyzip", "~> 2.3", require: "zip"
gem "saml2", "~> 3.1"
gem "sanitize", "~> 6.0", require: false
gem "sentry-rails", "~> 5.10"
gem "sentry-inst_jobs", "~> 5.10"
gem "twilio-ruby", "~> 7.0", require: false
gem "vault", "~> 0.17", require: false
gem "vericite_api", "1.5.3"
gem "wcag_color_contrast", "0.1.0"

path "../gems" do
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
  gem "legacy_multipart"
  gem "live_events"
  gem "lti-advantage"
  gem "lti_outbound"
  gem "paginated_collection"
  gem "request_context"
  gem "stringify_ids"
  gem "turnitin_api"
  gem "twitter"
  gem "utf8_cleaner"
  gem "workflow"
end

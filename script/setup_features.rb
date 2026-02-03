#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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
#
#
require "bundler/setup"

# This is a standalone CLI script, not a spec file

# Validate parameters - secret word is mandatory, param is optional
if ARGV.empty?
  $stdout.puts "Error: Secret word is required"
  $stdout.puts "Usage: #{$PROGRAM_NAME} SECRET_WORD [JIRA_TICKET|PERCENTAGE]"
  $stdout.puts "Examples:"
  $stdout.puts "  #{$PROGRAM_NAME} my_secret RCX-3767"
  $stdout.puts "  #{$PROGRAM_NAME} my_secret 85"
  $stdout.puts "  #{$PROGRAM_NAME} my_secret          # Defaults to 70%"
  raise SystemExit, 1
end

secret_word = ARGV[0]
param = ARGV[1] || "70"

# Show default message if no second parameter provided
if ARGV[1].nil?
  $stdout.puts "⚠ No parameter provided - defaulting to global features with 70% usage"
  $stdout.puts ""
end

# Determine if parameter is a Jira ticket or percentage
# Jira ticket format: WORD-NUMBER (e.g., RCX-3767, INTEROP-12345)
# Percentage: just a number (integer or float)
is_jira_ticket = param.match?(/^[A-Z]+-\d+$/i)
is_percentage = param.match?(/^\d+(\.\d+)?$/)

unless is_jira_ticket || is_percentage
  $stdout.puts "Error: Invalid parameter format"
  $stdout.puts "Expected: JIRA_TICKET (e.g., RCX-3767) or PERCENTAGE (e.g., 70 or 0.01)"
  raise SystemExit, 1
end

mode = is_jira_ticket ? :customer : :global

# Check if we're running inside Docker by looking for POSTGRES_PASSWORD env var
# If not, re-execute this script inside Docker
unless ENV["POSTGRES_PASSWORD"]
  $stdout.puts "Running inside Docker container..."
  exec("docker", "compose", "run", "--rm", "web", "ruby", __FILE__, secret_word, param)
end

require "json"
require "net/http"
require "uri"
require "fileutils"
require "base64"

# Load Rails environment
require_relative "../config/environment"

# API configuration
API_HOST = "https://feature-flag-nonprod.quality-nonprod.us-east-2.inseng.io"

# Method to get API key using secret word
def get_api_key(secret_word)
  # Encode the secret word 6 times
  encoded_secret = secret_word
  6.times do
    encoded_secret = Base64.strict_encode64(encoded_secret)
  end

  # Make POST request to get API key
  uri = URI("#{API_HOST}/api/auth/get-key")
  http = Net::HTTP.new(uri.host, uri.port)

  # Enable SSL if using HTTPS
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
  request.body = { secret: encoded_secret }.to_json

  response = http.request(request)

  unless response.is_a?(Net::HTTPSuccess)
    $stdout.puts "\e[1m\e[31m✗ Error getting API key: #{response.code} #{response.message}\e[0m"
    $stdout.puts "\e[1m\e[31m  Response: #{response.body}\e[0m"
    raise SystemExit, 1
  end

  # Parse response and extract API key
  response_data = JSON.parse(response.body)
  api_key = response_data["api_key"] || response_data["apiKey"] || response_data["key"]

  unless api_key
    $stdout.puts "\e[1m\e[31m✗ Error: No API key found in response\e[0m"
    $stdout.puts "\e[1m\e[31m  Response: #{response.body}\e[0m"
    raise SystemExit, 1
  end

  api_key
rescue => e
  $stdout.puts "\e[1m\e[31m✗ Error getting API key: #{e.message}\e[0m"
  raise SystemExit, 1
end

# Get API key for authenticated requests
$stdout.puts "Authenticating with secret word..."
API_KEY = get_api_key(secret_word)
$stdout.puts "✓ Authentication successful"
$stdout.puts ""

$stdout.puts "\e[1m\e[36m==========================================\e[0m"
$stdout.puts "\e[1m\e[36mSetting up #{(mode == :customer) ? "customer" : "global"} features\e[0m"
$stdout.puts "\e[1m\e[36m==========================================\e[0m"
$stdout.puts ""

# Create temp directory if it doesn't exist
temp_dir = "script/temp"
FileUtils.mkdir_p(temp_dir)

# Step 0: Pull feature flags from API
$stdout.puts "Step 0: Pulling feature flags from API..."
api_url = "#{API_HOST}/api/feature-flags?saltnpepa=true"

# Define output file path (used at end of script for cleanup)
root_dir = File.expand_path("..", __dir__)
output_dir = File.join(root_dir, "config", "feature_flags")
pulled_feature_flags_file = File.join(output_dir, "z_saltNpepa_pull.yml")

begin
  uri = URI(api_url)
  http = Net::HTTP.new(uri.host, uri.port)

  # Enable SSL if using HTTPS
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Get.new(uri.request_uri)
  request["X-API-Key"] = API_KEY

  http_response = http.request(request)
  response = http_response.body

  # Ensure the directory exists
  FileUtils.mkdir_p(output_dir)

  # Write the response to file
  File.write(pulled_feature_flags_file, response.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace))

  file_size = File.size(pulled_feature_flags_file)
  line_count = File.readlines(pulled_feature_flags_file).count

  $stdout.puts "✓ Successfully pulled and saved feature flags"
  $stdout.puts "  File: #{pulled_feature_flags_file}"
  $stdout.puts "  Size: #{file_size} bytes (#{line_count} lines)"
rescue => e
  $stdout.puts "\e[1m\e[31m✗ Error pulling feature flags: #{e.message}\e[0m"
  $stdout.puts "\e[1m\e[33m⚠ Continuing with existing feature flags...\e[0m"
end
$stdout.puts ""

# Step 1: Save all enabled features to database with state='off'
$stdout.puts "Step 1: Flushing out DB and saving all currently enabled features from feature flag with state='off'..."

# Capture initial state BEFORE making any changes
$stdout.puts "Capturing initial feature flag state for comparison..."
initial_state = {}
FeatureFlag.find_each do |flag|
  initial_state["#{flag.feature}:#{flag.context_type}:#{flag.context_id}"] = flag.state
end
$stdout.puts "✓ Captured #{initial_state.length} initial feature flag states"
$stdout.puts ""

$stdout.puts "Step 1a: Clearing existing feature_flags table..."
deleted_count = FeatureFlag.delete_all
$stdout.puts "✓ Deleted #{deleted_count} existing feature flag records"
$stdout.puts ""

account = Account.find(1)

$stdout.puts "Step 1b: Collecting all enabled features..."

# Collect all features with their properties
all_features = []

Feature.applicable_features(account).each do |fd|
  flag = account.lookup_feature_flag(fd.feature, skip_cache: true)

  # Only include if enabled
  next unless flag&.enabled?

  # Get display_name - call it if it's a Proc, otherwise use it directly
  display_name = fd.display_name.is_a?(Proc) ? fd.display_name.call : fd.display_name

  all_features << {
    feature: fd.feature,
    display_name:,
    applies_to: fd.applies_to,
    state: flag.state
  }
end

$stdout.puts "✓ Found #{all_features.length} enabled features"
$stdout.puts ""

$stdout.puts "Step 1c: Saving features to feature_flags table with state=off..."

created_count = 0
skipped_count = 0

all_features.each do |feature_info|
  # Create feature flag record with context_type = Account
  flag = FeatureFlag.find_or_initialize_by(
    context_type: "Account",
    context_id: account.id,
    feature: feature_info[:feature]
  )

  flag.state = "off"
  flag.save!

  created_count += 1
rescue => e
  $stdout.puts "  ✗ Error saving '#{feature_info[:feature]}': #{e.message}"
  skipped_count += 1
end

$stdout.puts "✓ Successfully saved #{created_count} features to database with state='off'"
if skipped_count > 0
  $stdout.puts "⚠ Skipped/Failed: #{skipped_count}"
end
$stdout.puts ""

# Step 2: Fetch features data (different for customer vs global)
features_response = nil
cloud_guid = nil
jira_issue = nil

if mode == :customer
  jira_issue = param

  $stdout.puts "Step 2: Fetching Jira issue data for #{jira_issue}..."

  jira_uri = URI("#{API_HOST}/api/jira-salesforce?jira_issue=#{jira_issue}")

  http = Net::HTTP.new(jira_uri.host, jira_uri.port)

  # Enable SSL if using HTTPS
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Get.new(jira_uri.request_uri)
  request["X-API-Key"] = API_KEY

  http_response = http.request(request)
  jira_response = http_response.body

  jira_file = "#{temp_dir}/jira_response.json"
  File.write(jira_file, jira_response.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace))

  $stdout.puts "✓ Saved to #{jira_file}"
  $stdout.puts ""

  # Extract cloud_guid__c from first customer in the response
  $stdout.puts "Step 2b: Extracting cloud_guid__c from first customer..."
  jira_data = JSON.parse(jira_response)

  # Check if Jira data is valid
  if jira_data["data"].blank?
    $stdout.puts "⚠ Warning: Could not extract cloud_guid__c from Jira issue #{jira_issue}"
    $stdout.puts "\e[1m\e[33m⚠ ═══════════════════════════════════════════════════════════════\e[0m"
    $stdout.puts "\e[1m\e[33m⚠ FALLING BACK TO GLOBAL FEATURES WITH 70% USAGE\e[0m"
    $stdout.puts "\e[1m\e[33m⚠ ═══════════════════════════════════════════════════════════════\e[0m"
    $stdout.puts ""
    mode = :global
    param = "70"
    # Fall through to global mode below
  else
    cloud_guid = jira_data["data"][0]["cloud_guid__c"]

    if cloud_guid.blank?
      $stdout.puts "⚠ Warning: cloud_guid__c is empty for Jira issue #{jira_issue}"
      $stdout.puts "\e[1m\e[33m⚠ ═══════════════════════════════════════════════════════════════\e[0m"
      $stdout.puts "\e[1m\e[33m⚠ FALLING BACK TO GLOBAL FEATURES WITH 70% USAGE\e[0m"
      $stdout.puts "\e[1m\e[33m⚠ ═══════════════════════════════════════════════════════════════\e[0m"
      $stdout.puts ""
      mode = :global
      param = "70"
      # Fall through to global mode below
    else
      $stdout.puts "✓ Found cloud_guid__c: #{cloud_guid}"
      $stdout.puts ""

      # Step 3: Fetch customer features using cloud_guid__c
      $stdout.puts "Step 3: Fetching customer features for UUID: #{cloud_guid}..."

      features_uri = URI("#{API_HOST}/api/features?uuid=#{cloud_guid}")

      http = Net::HTTP.new(features_uri.host, features_uri.port)

      # Enable SSL if using HTTPS
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Get.new(features_uri.request_uri)
      request["X-API-Key"] = API_KEY

      http_response = http.request(request)
      features_response = http_response.body

      features_file = "#{temp_dir}/customer_features.json"
      File.write(features_file, features_response.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace))

      $stdout.puts "✓ Saved to #{features_file}"
    end
  end
end

if mode == :global
  # Global mode
  percent = param

  $stdout.puts "Step 2: Fetching global feature usage (percent=#{percent})..."

  features_uri = URI("#{API_HOST}/api/feature-usage-global?percent=#{percent}")

  http = Net::HTTP.new(features_uri.host, features_uri.port)

  # Enable SSL if using HTTPS
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Get.new(features_uri.request_uri)
  request["X-API-Key"] = API_KEY

  http_response = http.request(request)
  features_response = http_response.body

  features_file = "#{temp_dir}/feature_usage_global.json"
  File.write(features_file, features_response.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace))

  $stdout.puts "✓ Saved to #{features_file}"
end

$stdout.puts ""

# Step 3/4: Show current database state
step_num = (mode == :customer) ? 4 : 3
$stdout.puts "Step #{step_num}: Checking current feature_flags table state..."

flags = FeatureFlag.order(:feature)

$stdout.puts "Current records in feature_flags table: #{flags.count}"

if flags.any?
  # Count unique feature names
  unique_features = flags.map(&:feature).uniq
  $stdout.puts "Unique feature names: #{unique_features.length}"

  if flags.count != unique_features.length
    $stdout.puts "⚠ Warning: #{flags.count - unique_features.length} duplicate records detected"
  end

  $stdout.puts ""
  # Group by context_type
  by_context_type = flags.group_by(&:context_type)

  by_context_type.each do |context_type, type_flags|
    $stdout.puts "=========================================="
    $stdout.puts "#{context_type.upcase} CONTEXT"
    $stdout.puts "=========================================="
    $stdout.puts "Total: #{type_flags.length}"
    $stdout.puts ""

    type_flags.first(5).each do |flag|
      $stdout.puts "  • #{flag.feature} (state: #{flag.state}, context_id: #{flag.context_id})"
    end
    $stdout.puts "  ... and #{type_flags.length - 5} more" if type_flags.length > 5
    $stdout.puts ""
  end

  $stdout.puts "=========================================="
  $stdout.puts "SUMMARY BY CONTEXT TYPE"
  $stdout.puts "=========================================="
  by_context_type.each do |context_type, type_flags|
    $stdout.puts "  #{context_type}: #{type_flags.length} features"
  end
else
  $stdout.puts "✓ Database is empty"
end

$stdout.puts ""

# Step 4/5: Update matching features with states
# Global mode: all features → "on"
# Customer mode: "on"/"allowed_on" → "on", others → "off"
step_num = (mode == :customer) ? 5 : 4
$stdout.puts "Step #{step_num}: Updating matching features with states from API..."
$stdout.puts ""

feature_data = JSON.parse(features_response)

# Check if data exists
if feature_data.blank?
  $stdout.puts "Error: No feature data found in the JSON response"
  raise SystemExit, 1
end

default_account = Account.find(1)

created_count = 0
skipped_count = 0

# Parse features from response
features_to_apply = []

if feature_data.is_a?(Array)
  features_to_apply = feature_data
elsif feature_data["data"].is_a?(Array)
  features_to_apply = feature_data["data"]
elsif feature_data["data"].is_a?(Hash)
  data_hash = feature_data["data"]
  first_value = data_hash.values.first

  if first_value.is_a?(Array)
    data_hash.each_value do |value|
      features_to_apply.concat(value) if value.is_a?(Array)
    end
  elsif first_value.is_a?(Hash)
    data_hash.each do |feature_name, feature_props|
      features_to_apply << {
        "feature" => feature_name,
        "context_type" => feature_props["context_type"],
        "display_name" => feature_props["display_name"],
        "state" => feature_props["state"]
      }
    end
  end
elsif feature_data["features"].is_a?(Array)
  features_to_apply = feature_data["features"]
elsif feature_data.is_a?(Hash) && !feature_data["data"] && !feature_data["features"]
  # Handle top-level hash where keys are feature names (e.g., /api/features?uuid=...)
  feature_data.each do |feature_name, feature_props|
    next unless feature_props.is_a?(Hash) # Skip non-hash values

    features_to_apply << {
      "feature" => feature_name,
      "context_type" => feature_props["context_type"],
      "display_name" => feature_props["display_name"],
      "state" => feature_props["state"]
    }
  end
else
  $stdout.puts "Error: Unexpected data structure in API response"
  $stdout.puts "Response structure: #{feature_data.keys.inspect}"
  raise SystemExit, 1
end

if features_to_apply.empty?
  $stdout.puts "Warning: No features found to apply"
end

$stdout.puts "Total features to process: #{features_to_apply.length}"

# Check for unique feature names
feature_names = features_to_apply.filter_map { |f| f["feature"] || f["name"] || f["feature_name"] }
unique_feature_names = feature_names.uniq
if feature_names.length != unique_feature_names.length
  $stdout.puts "⚠ Warning: Found duplicate feature names!"
  $stdout.puts "Total features: #{feature_names.length}, Unique features: #{unique_feature_names.length}"
  duplicates = feature_names.group_by(&:itself).select { |_k, v| v.size > 1 }.keys
  $stdout.puts "Duplicate features: #{duplicates.inspect}"
end
$stdout.puts ""

features_to_apply.each do |feature_info|
  feature_name = feature_info["feature"] || feature_info["name"] || feature_info["feature_name"]
  context_type = "Account"

  unless feature_name
    $stdout.puts "⚠ Skipping feature with no name: #{feature_info.inspect}"
    skipped_count += 1
    next
  end

  # Check if feature exists in Canvas
  feature_definition = Feature.definitions[feature_name]

  unless feature_definition
    $stdout.puts "⚠ Feature '#{feature_name}' not found in Canvas definitions - skipping"
    skipped_count += 1
    next
  end

  # Determine target state based on mode
  # Global mode (percentage): all features = "on"
  # Customer mode (Jira ticket): "on"/"allowed_on" → "on", others → "off"
  api_state = feature_info["state"]
  target_state = if mode == :global || ["on", "allowed_on"].include?(api_state)
                   "on"
                 else
                   "off"
                 end

  # Find existing feature flag record (from Step 1)
  flag = FeatureFlag.find_by(
    context_type:,
    context_id: default_account.id,
    feature: feature_name
  )

  if flag
    # Update existing record with state from API
    old_state = flag.state
    flag.state = target_state
    flag.save!
    created_count += 1
    $stdout.puts "✓ Updated: #{feature_name} → state: #{old_state} → #{flag.state} (API: #{api_state}), context: #{context_type}##{default_account.id}"
  else
    # Feature not in database from Step 1, create new record
    flag = FeatureFlag.create!(
      context_type:,
      context_id: default_account.id,
      feature: feature_name,
      state: target_state
    )
    created_count += 1
    $stdout.puts "✓ Created: #{feature_name} → state: #{flag.state} (API: #{api_state}), context: #{context_type}##{default_account.id}"
  end

  # Handle visibility conditions for enabled features (only if state is "on")
  if target_state == "on" && feature_definition.respond_to?(:visible_on) && feature_definition.visible_on
    case feature_definition.visible_on
    when "usage_metrics_allowed_hook"
      # Enable usage metrics visibility in account settings
      unless default_account.settings[:enable_usage_metrics]
        default_account.settings[:enable_usage_metrics] = true
        default_account.save!
        $stdout.puts "  ↳ Enabled visibility: account.settings[:enable_usage_metrics] = true"
      end
    when "docviewer_enable_iwork_visible_on_hook"
      # Enable iWork files visibility in account settings
      unless default_account.settings[:docviewer_enable_iwork_files]
        default_account.settings[:docviewer_enable_iwork_files] = true
        default_account.save!
        $stdout.puts "  ↳ Enabled visibility: account.settings[:docviewer_enable_iwork_files] = true"
      end
    when "quizzes_next_visible_on_hook"
      # Quizzes.Next visibility requires provision/lti setting - skip automatic config
      $stdout.puts "  ↳ Note: Feature requires provision/lti configuration (not auto-configured)"
    when "oak_flag_visible_on_hook"
      # Oak visibility is region-based - no account setting needed
      $stdout.puts "  ↳ Note: Feature visibility is region-based (no account setting needed)"
    when "block_content_editor_flag_enabled", "a11y_checker_flag_enabled"
      # These check for the feature flag itself being enabled - no additional setting needed
      $stdout.puts "  ↳ Note: Feature visibility based on flag state (no additional setting needed)"
    else
      $stdout.puts "  ↳ Note: Feature has visibility hook '#{feature_definition.visible_on}' (not auto-configured)"
    end
  end
rescue => e
  $stdout.puts "✗ Error applying feature '#{feature_name}': #{e.message}"
  skipped_count += 1
end

$stdout.puts ""
$stdout.puts "\e[1m\e[36m==========================================\e[0m"
$stdout.puts "\e[1m\e[36mEXECUTION SUMMARY\e[0m"
$stdout.puts "\e[1m\e[36m==========================================\e[0m"
$stdout.puts ""

if mode == :customer
  # Extract customer info from response
  jira_data = JSON.parse(File.read("#{temp_dir}/jira_response.json"))
  customer_name = jira_data["data"][0]["accountname__c"] || "Unknown"
  customer_count = jira_data["total_cases"] || 0
  feature_count = feature_data["total_features"] || 0

  $stdout.puts "\e[1m\e[36mJira Issue: #{jira_issue}\e[0m"
  $stdout.puts "\e[1m\e[36mCustomer: #{customer_name}\e[0m"
  $stdout.puts "\e[1m\e[36mUUID (cloud_guid__c): #{cloud_guid}\e[0m"
  $stdout.puts "\e[1m\e[36mTotal customers in Jira issue: #{customer_count}\e[0m"
  $stdout.puts "\e[1m\e[36mTotal features for customer: #{feature_count}\e[0m"
else
  $stdout.puts "\e[1m\e[36mGlobal usage percent: #{param}\e[0m"
end

$stdout.puts ""
$stdout.puts "\e[1mFeature Application Summary:\e[0m"
$stdout.puts "\e[1m\e[36mTotal features in API response: #{features_to_apply.length}\e[0m"
$stdout.puts "\e[1m\e[36mSuccessfully applied: #{created_count}\e[0m"
$stdout.puts "\e[1m\e[36mSkipped/Failed: #{skipped_count}\e[0m"
$stdout.puts "\e[1m\e[36mFinal database count: #{FeatureFlag.count}\e[0m"

# Capture final state and compare with initial state
final_state = {}
FeatureFlag.find_each do |flag|
  final_state["#{flag.feature}:#{flag.context_type}:#{flag.context_id}"] = flag.state
end

# Calculate changes
changes = []

# Check all features in final state
final_state.each do |key, final_value|
  parts = key.split(":")
  feature_name = parts[0]
  context_type = parts[1]
  display_name = "#{feature_name} [#{context_type}]"

  if initial_state.key?(key)
    initial_value = initial_state[key]
    if initial_value != final_value
      before_symbol = (initial_value == "on") ? "✓" : "✗"
      after_symbol = (final_value == "on") ? "✓" : "✗"
      changes << { name: display_name, before: before_symbol, after: after_symbol }
    end
  else
    # New feature that didn't exist before
    before_symbol = "✗"
    after_symbol = (final_value == "on") ? "✓" : "✗"
    changes << { name: display_name, before: before_symbol, after: after_symbol }
  end
end

# Check for features that existed in initial state but are missing in final state (deleted)
initial_state.each do |key, initial_value|
  next if final_state.key?(key) # Already processed above

  parts = key.split(":")
  feature_name = parts[0]
  context_type = parts[1]
  display_name = "#{feature_name} [#{context_type}]"

  before_symbol = (initial_value == "on") ? "✓" : "✗"
  after_symbol = "✗" # Deleted features are considered disabled
  changes << { name: display_name, before: before_symbol, after: after_symbol }
end

# Display changes only if there are any
$stdout.puts ""

if changes.any?
  $stdout.puts "\e[1m\e[36m==========================================\e[0m"
  $stdout.puts "\e[1m\e[36mFEATURE CHANGES (BEFORE → AFTER)\e[0m"
  $stdout.puts "\e[1m\e[36m==========================================\e[0m"
  $stdout.puts ""

  # Find the longest feature name for column width
  max_name_length = changes.map { |c| c[:name].length }.max || 0
  max_name_length = [max_name_length, 40].max # Minimum 40 characters for "Feature Name"

  # Print table header
  header = format("%-#{max_name_length}s  %-10s  %-10s", "Feature Name", "Before", "After")
  $stdout.puts "\e[1m#{header}\e[0m"
  $stdout.puts "-" * (max_name_length + 24)

  # Print each change
  changes.sort_by { |c| c[:name] }.each do |change|
    before_color = (change[:before] == "✓") ? "\e[32m" : "\e[31m"
    after_color = (change[:after] == "✓") ? "\e[32m" : "\e[31m"

    row = format("%-#{max_name_length}s  #{before_color}%-10s\e[0m  #{after_color}%-10s\e[0m",
                 change[:name],
                 change[:before],
                 change[:after])
    $stdout.puts row
  end

  $stdout.puts ""
  $stdout.puts "\e[1m\e[36mTotal Changes: #{changes.length}\e[0m"
else
  $stdout.puts "\e[1m\e[33m==========================================\e[0m"
  $stdout.puts "\e[1m\e[33mNO FEATURE CHANGES\e[0m"
  $stdout.puts "\e[1m\e[33m==========================================\e[0m"
  $stdout.puts ""
  $stdout.puts "No features were changed. All features remain in their previous state."
end

# Step 5/6: Display enabled features
step_num = (mode == :customer) ? 6 : 5
$stdout.puts ""
$stdout.puts "Step #{step_num}: Displaying enabled features..."
$stdout.puts ""

# Collect all features with their properties
all_features = []

Feature.applicable_features(account).each do |fd|
  flag = account.lookup_feature_flag(fd.feature, skip_cache: true)

  # Only include if enabled
  next unless flag&.enabled?

  display_name = fd.display_name.is_a?(Proc) ? fd.display_name.call : fd.display_name

  all_features << {
    feature: fd.feature,
    display_name:,
    applies_to: fd.applies_to,
    state: flag.state
  }
end

# Separate by applies_to and sort by display_name
account_context_types = %w[Account RootAccount]
account_features = all_features.select { |f| account_context_types.include?(f[:applies_to]) }.sort_by { |f| f[:display_name].to_s }
course_features = all_features.select { |f| f[:applies_to] == "Course" }.sort_by { |f| f[:display_name].to_s }

$stdout.puts "=== ACCOUNT LEVEL FEATURES (ENABLED) ==="
$stdout.puts "Total Account-level features enabled: #{account_features.length}"
account_features.each { |f| $stdout.puts "  ✓ #{f[:display_name]} (#{f[:feature]})" }

$stdout.puts ""
$stdout.puts "=== COURSE LEVEL FEATURES (ENABLED) ==="
$stdout.puts "Total Course-level features enabled: #{course_features.length}"
course_features.each { |f| $stdout.puts "  ✓ #{f[:display_name]} (#{f[:feature]})" }

$stdout.puts ""
$stdout.puts "\e[1m\e[32m==========================================\e[0m"
$stdout.puts "\e[1m\e[32mSetup complete!\e[0m"
$stdout.puts "\e[1m\e[32m==========================================\e[0m"

# Cleanup: Remove temp folder and all its contents
$stdout.puts ""
$stdout.puts "Cleaning up temporary files..."
FileUtils.rm_rf(temp_dir) # rubocop:disable Lint/NoFileUtilsRmRf
$stdout.puts "✓ Removed temp folder"

# Restart all Docker services
$stdout.puts ""
$stdout.puts "⏳ Waiting 5 seconds before restarting Docker services..."
# sleep 5

$stdout.puts "🔻 Stopping all Docker services..."
system("docker compose down")
$stdout.puts "✓ All services stopped"
$stdout.puts ""

$stdout.puts "⏳ Waiting for services to fully shut down..."
# sleep 3
$stdout.puts ""

$stdout.puts "🚀 Starting all Docker services..."
system("docker compose up -d")
$stdout.puts ""

$stdout.puts "⏳ Waiting for services to be ready..."
# sleep 10
$stdout.puts "✅ All Docker services restarted successfully!"
$stdout.puts ""

# Cleanup: Remove pulled feature flags file
if defined?(pulled_feature_flags_file) && File.exist?(pulled_feature_flags_file)
  $stdout.puts "Cleaning up pulled feature flags file..."
  File.delete(pulled_feature_flags_file)
  $stdout.puts "✓ Removed #{pulled_feature_flags_file}"
end

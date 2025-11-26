# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
# AI Experiences Usage Report Generator
#
# Usage in Rails console:
#   load 'script/ai_experiences_report.rb'
#   AIExperiencesReportGenerator.run("2025-01-01", "2025-01-31", "/tmp/reports")
#
# Or create instance:
#   generator = AIExperiencesReportGenerator.new("2025-01-01", "2025-01-31", "/tmp/reports")
#   generator.generate
#

# rubocop:disable Rails/Output
class AIExperiencesReportGenerator
  BATCH_SIZE = (ENV["BATCH_SIZE"] || 100).to_i
  RATE_LIMIT_DELAY = (ENV["RATE_LIMIT_DELAY"] || 0.1).to_f

  def self.run(start_date, end_date, output_dir = "/tmp")
    generator = new(start_date, end_date, output_dir)
    generator.generate
  end

  def initialize(start_date, end_date, output_dir)
    @start_date = Date.parse(start_date.to_s)
    @end_date = Date.parse(end_date.to_s)
    @output_dir = output_dir || "/tmp"

    @account_cache = {}
    @user_cache = {}
    @all_conversations_cache = {}
    @conversation_metadata = {} # Maps conversation_id => {account:, shard:, user_id:}
    @region_base_urls = nil # Cache region URLs

    @bearer_token = ENV["LLM_CONVERSATION_BEARER_TOKEN"] || LLMConversationClient.bearer_token

    validate_config!
  end

  def generate
    puts "AI Experiences Report Generator"
    puts "================================"
    puts "Date range: #{@start_date} to #{@end_date}"
    puts "Output directory: #{@output_dir}"
    puts ""

    # Initialize output files
    conversations_file = File.join(@output_dir, "conversations_summary_#{@start_date}_#{@end_date}.csv")
    messages_file = File.join(@output_dir, "messages_detail_#{@start_date}_#{@end_date}.csv")
    users_file = File.join(@output_dir, "users_#{@start_date}_#{@end_date}.csv")
    accounts_file = File.join(@output_dir, "root_accounts_#{@start_date}_#{@end_date}.csv")
    metrics_file = File.join(@output_dir, "summary_metrics_#{@start_date}_#{@end_date}.json")
    errors_file = File.join(@output_dir, "errors_#{@start_date}_#{@end_date}.log")

    # Create output directory
    FileUtils.mkdir_p(@output_dir)

    # Initialize metrics
    metrics = {
      total_conversations: 0,
      total_messages: 0,
      failed_conversations: 0,
      employee_conversations: 0,
      non_employee_conversations: 0,
      total_message_characters: 0,
      accounts: Hash.new(0),
      users: Hash.new(0),
      employee_users: Set.new,
      non_employee_users: Set.new,
      employee_sandbox_accounts: Set.new,
      non_employee_sandbox_accounts: Set.new,
      date_range: { start: @start_date.to_s, end: @end_date.to_s }
    }

    # Track unique users and accounts for separate files
    users_data = {}
    accounts_data = {}

    # Open CSV files
    CSV.open(conversations_file, "wb") do |conv_csv|
      CSV.open(messages_file, "wb") do |msg_csv|
        CSV.open(users_file, "wb") do |users_csv|
          CSV.open(accounts_file, "wb") do |accounts_csv|
            File.open(errors_file, "w") do |error_log|
              # Write headers
              conv_csv << %w[
                conversation_uuid
                root_account_name
                root_account_id
                user_name
                user_id
                is_employee
                created_at
                updated_at
                message_count
                user_message_count
                assistant_message_count
              ]

              msg_csv << %w[
                conversation_uuid
                message_uuid
                root_account_name
                user_name
                seq_num
                role
                created_at
                text_length
                text_preview
              ]

              users_csv << %w[
                user_id
                user_uuid
                user_name
                is_employee
                conversation_count
              ]

              accounts_csv << %w[
                account_id
                account_uuid
                account_name
                external_status
                conversation_count
              ]

              # Fetch and process conversations
              offset = 0
              loop do
                puts "Fetching conversations #{offset} to #{offset + BATCH_SIZE}..."

                conversations = fetch_conversations(offset)
                break if conversations.empty?

                # Pre-fetch metadata (accounts and shards) for this batch
                prefetch_metadata(conversations)

                conversations.each_with_index do |conv, idx|
                  process_conversation(conv, conv_csv, msg_csv, metrics, users_data, accounts_data)

                  if (offset + idx + 1) % 50 == 0
                    puts "  Processed #{offset + idx + 1} conversations..."
                  end

                  sleep(RATE_LIMIT_DELAY) if RATE_LIMIT_DELAY > 0 # rubocop:disable Lint/NoSleep
                rescue => e
                  metrics[:failed_conversations] += 1
                  error_log.puts "[#{Time.zone.now}] Error processing conversation #{conv["id"]}: #{e.message}"
                  error_log.puts e.backtrace.join("\n  ")
                  puts "  WARNING: Failed to process conversation #{conv["id"]}"
                end

                offset += BATCH_SIZE
                break if conversations.size < BATCH_SIZE
              end

              # Write users data
              users_data.values.sort_by { |u| -u[:conversation_count] }.each do |user_info|
                users_csv << [
                  user_info[:id],
                  user_info[:uuid],
                  user_info[:name],
                  user_info[:is_employee],
                  user_info[:conversation_count]
                ]
              end

              # Write accounts data
              accounts_data.values.sort_by { |a| -a[:conversation_count] }.each do |account_info|
                accounts_csv << [
                  account_info[:id],
                  account_info[:uuid],
                  account_info[:name],
                  account_info[:external_status],
                  account_info[:conversation_count]
                ]
              end
            end
          end
        end
      end
    end

    # Calculate summary metrics
    metrics[:avg_messages_per_conversation] =
      if metrics[:total_conversations] > 0
        (metrics[:total_messages].to_f / metrics[:total_conversations]).round(2)
      else
        0
      end

    metrics[:avg_message_length] =
      if metrics[:total_messages] > 0
        (metrics[:total_message_characters].to_f / metrics[:total_messages]).round(2)
      else
        0
      end

    metrics[:top_accounts] = metrics[:accounts]
                             .sort_by { |_, count| -count }
                             .first(10)
                             .map { |name, count| { name:, conversation_count: count } }

    metrics[:top_users] = metrics[:users]
                          .sort_by { |_, count| -count }
                          .first(10)
                          .map { |name, count| { name:, conversation_count: count } }

    # Convert sets to counts
    metrics[:employee_users_count] = metrics[:employee_users].size
    metrics[:non_employee_users_count] = metrics[:non_employee_users].size
    metrics[:employee_sandbox_accounts_count] = metrics[:employee_sandbox_accounts].size
    metrics[:non_employee_sandbox_accounts_count] = metrics[:non_employee_sandbox_accounts].size

    # Remove raw counts and sets
    metrics.delete(:accounts)
    metrics.delete(:users)
    metrics.delete(:employee_users)
    metrics.delete(:non_employee_users)
    metrics.delete(:employee_sandbox_accounts)
    metrics.delete(:non_employee_sandbox_accounts)
    metrics.delete(:total_message_characters)

    # Write metrics file
    File.write(metrics_file, JSON.pretty_generate(metrics))

    # Print summary
    puts ""
    puts "Report Generation Complete!"
    puts "==========================="
    puts "Total conversations: #{metrics[:total_conversations]}"
    puts "Total messages: #{metrics[:total_messages]}"
    puts "Failed conversations: #{metrics[:failed_conversations]}"
    puts "Avg messages/conversation: #{metrics[:avg_messages_per_conversation]}"
    puts ""
    puts "Output files:"
    puts "  Conversations: #{conversations_file}"
    puts "  Messages: #{messages_file}"
    puts "  Users: #{users_file}"
    puts "  Root Accounts: #{accounts_file}"
    puts "  Metrics: #{metrics_file}"
    puts "  Errors: #{errors_file}" if metrics[:failed_conversations] > 0
  end

  private

  def validate_config!
    raise "Bearer token not configured" if @bearer_token.blank?
    raise "Invalid date range" if @end_date < @start_date
  end

  def region_base_urls
    @region_base_urls ||= begin
      # Get all configured region URLs (prod only)
      # Check for all llm_conversation_base_url settings
      regions = Setting.where("name LIKE ?", "llm_conversation_base_url%").map do |setting|
        { name: setting.name, url: setting.value }
      end

      # Filter to only production URLs (must contain "-prod")
      regions.select! do |region|
        region[:url]&.include?("-prod")
      end

      raise "No production llm_conversation_base_url settings found" if regions.empty?

      regions
    end
  end

  def fetch_conversations(offset)
    # NOTE: llm-conversation API doesn't support pagination or date filtering
    # GET /conversations returns ALL conversations ordered by created_at DESC
    # We fetch once per region and cache, then filter by date in memory

    @all_conversations ||= begin
      puts "Fetching conversations from all regions..."
      all_regions_conversations = []

      regions = region_base_urls

      regions.each do |region_config|
        puts "  Fetching from #{region_config[:name]}..."
        base_url = region_config[:url]
        next unless base_url

        uri = URI("#{base_url}/conversations")

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{@bearer_token}"
        request["Content-Type"] = "application/json"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          conversations = data["data"] || []

          # Tag each conversation with its region and URL
          conversations.each do |conv|
            conv["_region"] = region_config[:name]
            conv["_base_url"] = base_url
          end

          all_regions_conversations.concat(conversations)
          puts "    Found #{conversations.size} conversations"
        else
          puts "    WARNING: Failed to fetch from #{region_config[:name]}: #{response.code}"
        end
      rescue => e
        puts "    ERROR: Failed to fetch from #{region_config[:name]}: #{e.message}"
      end

      # Filter by date range and exclude test users
      test_user_ids = %w[user_jedi user_trekkie user_emperor]
      filtered = all_regions_conversations.select do |conv|
        created_at = Time.zone.parse(conv["created_at"])
        created_at.between?(@start_date, @end_date + 1) && !test_user_ids.include?(conv["user_id"])
      end

      puts ""
      puts "Total conversations across all regions: #{all_regions_conversations.size}"
      puts "Conversations in date range: #{filtered.size}"
      puts ""

      filtered
    end

    # Manual pagination
    @all_conversations[offset, BATCH_SIZE] || []
  end

  def fetch_messages(conversation_id, _root_account_uuid, conversation_base_url)
    # Use the same base URL that the conversation was fetched from
    base_url = conversation_base_url

    uri = URI("#{base_url}/conversations/#{conversation_id}/messages")

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@bearer_token}"
    request["Content-Type"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "API error: #{response.code} - #{response.body}"
    end

    data = JSON.parse(response.body)
    data["data"] || []
  end

  def process_conversation(conv, conv_csv, msg_csv, metrics, users_data, accounts_data)
    # Get cached metadata
    metadata = @conversation_metadata[conv["id"]] || {}
    account = metadata[:account]
    user = metadata[:user]
    is_employee = metadata[:is_employee]

    # Fetch messages from the same region URL that the conversation came from
    messages = fetch_messages(conv["id"], conv["root_account_id"], conv["_base_url"])

    # Count messages by role
    user_message_count = messages.count { |m| !m["is_llm_message"] }
    assistant_message_count = messages.count { |m| m["is_llm_message"] }

    # Write conversation row
    conv_csv << [
      conv["id"],
      account&.name || "Unknown",
      account&.id || "N/A",
      user&.name || "Unknown",
      user&.id || "N/A",
      is_employee,
      conv["created_at"],
      conv["updated_at"],
      messages.size,
      user_message_count,
      assistant_message_count
    ]

    # Write message rows
    messages.each_with_index do |msg, idx|
      text = msg["text"] || ""
      msg_csv << [
        conv["id"],
        msg["id"],
        account&.name || "Unknown",
        user&.name || "Unknown",
        idx + 1,
        msg["is_llm_message"] ? "Assistant" : "User",
        msg["created_at"],
        text.length,
        text[0..500] # First 500 chars as preview
      ]
    end

    # Update metrics
    metrics[:total_conversations] += 1
    metrics[:total_messages] += messages.size
    metrics[:accounts][account&.name || "Unknown"] += 1
    metrics[:users][user&.name || "Unknown"] += 1

    # Track employee vs non-employee
    if is_employee
      metrics[:employee_conversations] += 1
    else
      metrics[:non_employee_conversations] += 1
    end

    # Track message character count
    messages.each do |msg|
      text = msg["text"] || ""
      metrics[:total_message_characters] += text.length
    end

    # Track unique users by employee status
    if user
      if is_employee
        metrics[:employee_users].add(user.uuid)
      else
        metrics[:non_employee_users].add(user.uuid)
      end
    end

    # Track unique accounts by sandbox status
    if account
      if account.external_status == "employee_sandbox"
        metrics[:employee_sandbox_accounts].add(account.uuid)
      else
        metrics[:non_employee_sandbox_accounts].add(account.uuid)
      end
    end

    # Track user data
    if user
      user_key = user.uuid
      users_data[user_key] ||= {
        id: user.id,
        uuid: user.uuid,
        name: user.name,
        is_employee:,
        conversation_count: 0
      }
      users_data[user_key][:conversation_count] += 1
    end

    # Track account data
    if account
      account_key = account.uuid
      accounts_data[account_key] ||= {
        id: account.id,
        uuid: account.uuid,
        name: account.name,
        external_status: account.external_status,
        conversation_count: 0
      }
      accounts_data[account_key][:conversation_count] += 1
    end
  end

  # Pre-fetch accounts and users for a batch of conversations
  # Groups by shard to minimize shard activations and enable batch queries
  def prefetch_metadata(conversations)
    puts "  Pre-fetching metadata for #{conversations.size} conversations..."

    # Step 1: Fetch all accounts (batch) and group conversations by shard
    account_uuids = conversations.filter_map { |c| c["root_account_id"] if c["root_account_id"] != "default" }.uniq
    accounts_by_uuid = Account.where(uuid: account_uuids).index_by(&:uuid)

    # Cache accounts
    accounts_by_uuid.each { |uuid, account| @account_cache[uuid] = account }

    # Step 2: Group conversations by shard based on their account
    conversations_by_shard = Hash.new { |h, k| h[k] = [] }

    conversations.each do |conv|
      account = lookup_account(conv["root_account_id"])
      shard = account&.shard || Shard.default

      conversations_by_shard[shard] << conv

      @conversation_metadata[conv["id"]] = {
        account:,
        shard:,
        user_id: conv["user_id"],
        user: nil, # Will be populated in step 3
        is_employee: account&.external_status == "employee_sandbox" # Check account first
      }
    end

    # Step 3: Batch-fetch users per shard and check if they're site admins
    conversations_by_shard.each do |shard, shard_conversations|
      user_uuids = shard_conversations.filter_map { |c| c["user_id"] if c["user_id"] != "anonymous" }.uniq
      next if user_uuids.empty?

      users_by_uuid = shard.activate do
        User.where(uuid: user_uuids).index_by(&:uuid)
      end

      # Update metadata with users and check site admin status
      shard_conversations.each do |conv|
        user_uuid = conv["user_id"]
        user = users_by_uuid[user_uuid]
        @user_cache[user_uuid] = user if user
        @conversation_metadata[conv["id"]][:user] = user

        # Check if user is a site admin (employee) - only if not already marked as employee
        next unless user && !@conversation_metadata[conv["id"]][:is_employee]

        is_site_admin = Account.site_admin.shard.activate do
          Account.site_admin.users.where(id: user.id).exists?
        end
        @conversation_metadata[conv["id"]][:is_employee] = is_site_admin
      end
    end

    puts "    Loaded #{accounts_by_uuid.size} accounts and #{@user_cache.size} users across #{conversations_by_shard.size} shards"
  end

  def lookup_account(uuid)
    return nil if uuid.nil? || uuid == "default"

    @account_cache[uuid] ||= Account.find_by(uuid:)
  end
end

# Helper method to print usage
# rubocop:disable Naming/HeredocDelimiterNaming
def ai_report_usage
  puts <<~HELP
    AI Experiences Report Generator

    Usage:
      load 'script/ai_experiences_report.rb'
      AIExperiencesReportGenerator.run("2025-01-01", "2025-01-31", "/tmp/reports")

    Or:
      generator = AIExperiencesReportGenerator.new("2025-01-01", "2025-01-31", "/tmp")
      generator.generate
  HELP
end
# rubocop:enable Naming/HeredocDelimiterNaming

puts "Loaded AIExperiencesReportGenerator. Type 'ai_report_usage' for usage instructions."
# rubocop:enable Rails/Output

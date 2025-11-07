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
    metrics_file = File.join(@output_dir, "summary_metrics_#{@start_date}_#{@end_date}.json")
    errors_file = File.join(@output_dir, "errors_#{@start_date}_#{@end_date}.log")

    # Create output directory
    FileUtils.mkdir_p(@output_dir)

    # Initialize metrics
    metrics = {
      total_conversations: 0,
      total_messages: 0,
      failed_conversations: 0,
      accounts: Hash.new(0),
      users: Hash.new(0),
      date_range: { start: @start_date.to_s, end: @end_date.to_s }
    }

    # Open CSV files
    CSV.open(conversations_file, "wb") do |conv_csv|
      CSV.open(messages_file, "wb") do |msg_csv|
        File.open(errors_file, "w") do |error_log|
          # Write headers
          conv_csv << %w[
            conversation_uuid
            root_account_name
            root_account_id
            user_name
            user_id
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

          # Fetch and process conversations
          offset = 0
          loop do
            puts "Fetching conversations #{offset} to #{offset + BATCH_SIZE}..."

            conversations = fetch_conversations(offset)
            break if conversations.empty?

            conversations.each_with_index do |conv, idx|
              process_conversation(conv, conv_csv, msg_csv, metrics)

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

    metrics[:top_accounts] = metrics[:accounts]
                             .sort_by { |_, count| -count }
                             .first(10)
                             .map { |name, count| { name:, conversation_count: count } }

    metrics[:top_users] = metrics[:users]
                          .sort_by { |_, count| -count }
                          .first(10)
                          .map { |name, count| { name:, conversation_count: count } }

    # Remove raw counts
    metrics.delete(:accounts)
    metrics.delete(:users)

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
    puts "  Metrics: #{metrics_file}"
    puts "  Errors: #{errors_file}" if metrics[:failed_conversations] > 0
  end

  private

  def validate_config!
    raise "Bearer token not configured" if @bearer_token.blank?
    raise "Invalid date range" if @end_date < @start_date
  end

  def region_base_urls
    # Get all configured region URLs
    # Check for all llm_conversation_base_url settings
    regions = Setting.where("name LIKE ?", "llm_conversation_base_url%").map do |setting|
      { name: setting.name, url: setting.value }
    end

    # If no region-specific URLs, use default
    if regions.empty?
      default_url = Setting.get("llm_conversation_base_url", nil)
      regions << { name: "default", url: default_url } if default_url
    end

    regions
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

          # Tag each conversation with its region for debugging
          conversations.each { |conv| conv["_region"] = region_config[:name] }

          all_regions_conversations.concat(conversations)
          puts "    Found #{conversations.size} conversations"
        else
          puts "    WARNING: Failed to fetch from #{region_config[:name]}: #{response.code}"
        end
      rescue => e
        puts "    ERROR: Failed to fetch from #{region_config[:name]}: #{e.message}"
      end

      # Filter by date range in memory
      filtered = all_regions_conversations.select do |conv|
        created_at = Time.zone.parse(conv["created_at"])
        created_at.between?(@start_date, @end_date + 1)
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

  def fetch_messages(conversation_id, root_account_uuid)
    # Determine which region this root account belongs to
    base_url = get_base_url_for_account(root_account_uuid)

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

  def get_base_url_for_account(root_account_uuid)
    # Find the account to determine its region
    account = lookup_account(root_account_uuid)

    return Setting.get("llm_conversation_base_url", nil) unless account

    # Try to get region-specific URL based on account's shard
    shard = account.shard
    region = shard&.database_server&.id

    if region
      url = Setting.get("llm_conversation_base_url_#{region}", nil)
      return url if url
    end

    # Fallback to default
    Setting.get("llm_conversation_base_url", nil)
  end

  def process_conversation(conv, conv_csv, msg_csv, metrics)
    # Lookup Canvas data
    account = lookup_account(conv["root_account_id"])
    user = lookup_user(conv["user_id"])

    # Fetch messages (region-aware)
    messages = fetch_messages(conv["id"], conv["root_account_id"])

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
  end

  def lookup_account(uuid)
    return nil if uuid.nil? || uuid == "default"

    @account_cache[uuid] ||= begin
      # Search across all shards for the account
      account = nil
      Shard.with_each_shard do
        account = Account.find_by(uuid:)
        break if account
      end
      account
    end
  end

  def lookup_user(uuid)
    return nil if uuid.nil? || uuid == "anonymous"

    @user_cache[uuid] ||= begin
      # Search across all shards for the user
      user = nil
      Shard.with_each_shard do
        user = User.find_by(uuid:)
        break if user
      end
      user
    end
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

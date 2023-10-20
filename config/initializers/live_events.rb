# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class StubbedClient
  def self.put_records(records:, stream_name:)
    events = records.map { |e| JSON.parse(e[:data]).dig("attributes", "event_name") }.join(" | ")
    puts "Events #{events} put to stream #{stream_name}: #{records}"
    OpenStruct.new(
      records: records.map { OpenStruct.new(error_code: nil) }
    )
  end

  def self.stream_name
    "stubbed_kinesis_stream"
  end
end

Rails.configuration.to_prepare do
  LiveEvents.logger = Rails.logger
  LiveEvents.cache = Rails.cache
  LiveEvents.statsd = InstStatsd::Statsd
  LiveEvents.max_queue_size = -> { Setting.get("live_events_max_queue_size", 5000).to_i }
  LiveEvents.settings = -> { YAML.safe_load(DynamicSettings.find(tree: :private, default_ttl: 2.hours)["live_events.yml", failsafe_cache: Rails.root.join("config")] || "{}") }
  LiveEvents.aws_credentials = lambda do |settings|
    if settings["vault_credential_path"]
      Canvas::Vault::AwsCredentialProvider.new(settings["vault_credential_path"])
    else
      nil
    end
  end
  LiveEvents.stream_client = ->(settings) { StubbedClient if settings["stub_kinesis"] }
  # sometimes this async worker thread grabs a connection on a Setting read or similar.
  # We need it to be released or the main thread can have a real problem.
  LiveEvents.on_work_unit_end = -> { ActiveRecord::Base.clear_active_connections! }
end

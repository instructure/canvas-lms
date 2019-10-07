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
    events = records.map { |e| JSON.parse(e[:data]).dig('attributes', 'event_name') }.join(' | ')
    puts "Events #{events} put to stream #{stream_name}: #{records}"
  end

  def self.stream_name
    'stubbed_kinesis_stream'
  end
end

Rails.configuration.to_prepare do
  LiveEvents.logger = Rails.logger
  LiveEvents.cache = Rails.cache
  LiveEvents.statsd = InstStatsd::Statsd
  LiveEvents.max_queue_size = -> { Setting.get('live_events_max_queue_size', 5000).to_i }
  LiveEvents.settings = -> {
    plugin_settings = Canvas::Plugin.find(:live_events)&.settings
    if plugin_settings && Canvas::Plugin.value_to_boolean(plugin_settings['use_consul'])
      Canvas::DynamicSettings.find('live-events', default_ttl: 2.hours)
    elsif ENV['STUB_LIVE_EVENTS_KINESIS']
      plugin_settings.merge('stub_kinesis' => true)
    else
      plugin_settings
    end
  }
  LiveEvents.stream_client = StubbedClient if ENV['STUB_LIVE_EVENTS_KINESIS']
end

#
# Copyright (C) 2011 Instructure, Inc.
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

require 'atom'

class ExternalFeedAggregator
  def self.process
    ExternalFeedAggregator.new.process
  end

  def initialize
    @logger = Rails.logger
  end

  def process
    Shackles.activate(:slave) do
      start = Time.now.utc
      loop do
        feeds = ExternalFeed.to_be_polled(start).limit(1000).preload(context: :root_account).to_a
        break if feeds.empty?

        feeds.each do |feed|
          Shackles.activate(:master) do
            if !feed.context || feed.context.root_account.deleted? || feed.context.deleted?
              feed.update_attribute(:refresh_at, success_wait_seconds.seconds.from_now)
              next
            end

            process_feed(feed)
          end
        end
      end
    end
  end

  def parse_entries(feed, body)
    begin
      require 'rss/1.0'
      require 'rss/2.0'
      rss = RSS::Parser.parse(body, false)
      raise "Invalid rss feed" unless rss
      feed.title = rss.channel.title
      feed.save
      @logger.info("#{rss.items.length} rss items found")
      entries = feed.add_rss_entries(rss)
      @logger.info("#{entries.length} new entries added")
      return true
    rescue
      begin
        require 'atom'
        atom = Atom::Feed.load_feed(body)
        feed.title = atom.title.to_s
        feed.save
        @logger.info("#{atom.entries.length} atom entries found")
        entries = feed.add_atom_entries(atom)
        @logger.info("#{entries.length} new entries added")
        return true
      rescue
      end
    end
    false
  end

  def process_feed(feed)
    begin
      @logger.info("feed found: #{feed.url}")
      @logger.info('requesting entries')
      require 'net/http'

      response = CanvasHttp.get(feed.url)
      case response
      when Net::HTTPSuccess
        success = parse_entries(feed, response.body)
        @logger.info(success ? 'successful response' : '200 with no data returned')
        feed.consecutive_failures = 0 if success
        feed.update_attribute(:refresh_at, success_wait_seconds.seconds.from_now)
      else
        @logger.info("request failed #{response.class}")
        handle_failure(feed)
      end
    rescue CanvasHttp::Error, CanvasHttp::RelativeUriError, Timeout::Error, SocketError, SystemCallError => e
      @logger.info("request error: #{e}")
      handle_failure(feed)
    end
  end

  def handle_failure(feed)
    feed.increment(:failures)
    feed.increment(:consecutive_failures)
    feed.update_attribute(:refresh_at, failure_wait_seconds.seconds.from_now)
  end

  def success_wait_seconds
    Setting.get('external_feed_success_wait_seconds', 2.hours.to_s).to_f
  end

  def failure_wait_seconds
    Setting.get('external_feed_failure_wait_seconds', 30.minutes.to_s).to_f
  end
end

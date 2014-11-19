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

class ExternalFeedAggregator
  SUCCESS_WAIT_SECONDS = 1.hour     # time to refresh on a successful feed load with new entries
  NO_ENTRIES_WAIT_SECONDS = 2.hours # time to refresh on a successful feed load with NO new entries
  FAILURE_WAIT_SECONDS = 30.minutes # time to refresh on a failed feed load
  
  def self.process
    ExternalFeedAggregator.new.process
  end
  
  def initialize
    @logger = Rails.logger
  end
  
  def process
    Shackles.activate(:slave) do
      start = Time.now.utc
      begin
        feeds = ExternalFeed.to_be_polled(start).limit(1000).preload(context: :root_account).to_a
        feeds.each do |feed|
          Shackles.activate(:master) do
            if !feed.context || feed.context.root_account.deleted?
              feed.update_attribute(:refresh_at, Time.now.utc + NO_ENTRIES_WAIT_SECONDS)
              next
            end

            process_feed(feed)
          end
        end
      end while (!feeds.empty?)
    end
  end
  
  def parse_entries(feed, body)
    if feed.feed_type == 'rss/atom'
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
          feed.title = atom.title
          feed.save
          @logger.info("#{atom.entries.length} atom entries found")
          entries = feed.add_atom_entries(atom)
          @logger.info("#{entries.length} new entries added")
          return true
        rescue
        end
      end
    end
    false
  end
  
  def request_feed(url, attempt=0)
    return nil if attempt > 2
    url = URI.parse url
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.path)
    response = http.request(request)
    case response
    when Net::HTTPSuccess
      return response
    when Net::HTTPRedirection
      return new_response = request_feed(response['Location'], attempt + 1) || response
    else
      return response
    end
  end

  def process_feed(feed)
    begin
      @logger.info("feed found: #{feed.url}")
      @logger.info('requesting entries')
      require 'net/http'
      response = request_feed(feed.url)
      case response
      when Net::HTTPSuccess
        success = parse_entries(feed, response.body)
        @logger.info(success ? 'successful response' : '200 with no data returned')
        feed.consecutive_failures = 0 if success
        feed.update_attribute(:refresh_at, Time.now.utc + ((!@entries || @entries.empty?) ? NO_ENTRIES_WAIT_SECONDS : SUCCESS_WAIT_SECONDS))
      else
        @logger.info("request failed #{response.class.to_s}")
        feed.increment(:consecutive_failures)
        feed.increment(:failures)
        feed.update_attribute(:refresh_at, Time.now.utc + (FAILURE_WAIT_SECONDS))
      end
    rescue => e
      feed.increment(:consecutive_failures)
      feed.increment(:failures)
      feed.update_attribute(:refresh_at, Time.now.utc + (FAILURE_WAIT_SECONDS))
      ErrorReport.log_exception(:default, e, {
        :message => "External Feed aggregation failed",
        :feed_url => feed.url,
        :feed_id => feed.id,
        :user_id => feed.user_id,
      })
    end
  end
end

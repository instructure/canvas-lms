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

class TwitterSearcher
  REFRESH_INTERVAL = 30.minutes
  REFRESH_INTERVAL_EMPTY = 60.minutes
  MAX_TAGS_PER_PROCESS = 100
  
  def self.process
    TwitterSearcher.new.process
  end
  
  def initialize
    @logger = RAILS_DEFAULT_LOGGER
  end
  
  def process
    count = 0
    while hashtag = Hashtag.to_be_polled.first and (count += 1) < MAX_TAGS_PER_PROCESS
      hashtag.update_attributes(:refresh_at => Time.now.utc + REFRESH_INTERVAL)
      
      require 'net/http'
      @logger.info("hashtag found: #{hashtag}  -- requesting public twitter search")
      url = "http://search.twitter.com/search.json?q=%23#{CGI::escape(hashtag.hashtag)}&rpp=25"
      url += "&since_id=#{hashtag.last_result_id}" if hashtag.last_result_id
      url = URI.parse url
      @logger.info("request url: #{url}")
      http = Net::HTTP.new(url.host, url.port)
      request = Net::HTTP::Get.new(url.path + (url.query ? ('?' + url.query) : ''))
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        @logger.info('request succeeded')
        begin
          results = ActiveSupport::JSON.decode(response.body)["results"]
          @logger.info("found #{results.length} results")
          since_id = results[0]["id"] rescue nil
          results.each do |result|
            hashtag.add_short_message(nil, result, true)
          end
          hashtag.last_result_id = since_id if since_id
          hashtag.update_attributes(:refresh_at => Time.now.utc + (results.empty? ? REFRESH_INTERVAL_EMPTY : REFRESH_INTERVAL) )
          @logger.info('results successfully added')
        rescue => e
          ErrorReport.log_exception(:processing, e, {
            :message => e.to_s,
            :url => (request.url rescue "none")
          })
          @logger.info("** unexpected error: #{e.to_s}")
          @logger.info(e.backtrace)
        end
      else
        @logger.info("throttled! Retry after: #{response['Retry-After']}")
        
        # TODO: This assumes that Retry-After will always be sent as delta-seconds. We should probably support HTTP-date too:
        # http://webee.technion.ac.il/labs/comnet/netcourse/CIE/RFC/2068/201.htm
        wait_time = response['Retry-After'].to_i if response['Retry-After']
        hashtag.update_attributes(:refresh_at => Time.now.utc + wait_time)
      end
    end
    
    if count >= MAX_TAGS_PER_PROCESS
      @logger.info("more hashtags to process... scheduling another job")
      TwitterSearcher.send_later_engueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
    end
  end
end

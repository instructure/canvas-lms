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

class TwitterUserPoller
  REFRESH_INTERVAL = 30.minutes
  REFRESH_INTERVAL_EMPTY = 60.minutes
  MAX_PER_PROCESS = 100
  
  include Twitter
  
  def self.process
    TwitterUserPoller.new.process
  end
  
  def initialize
    @logger = RAILS_DEFAULT_LOGGER
  end
  
  def retrieve_tweets(service, attempt=0)
    @twitter_service = service
    twitter_list(nil, service.last_result_id)
  end
  
  def process
    count = 0
    
    while service = UserService.to_be_polled.for_service('twitter').first and (count += 1) < MAX_PER_PROCESS
      service.updated_at = Time.now.utc
      service.save
      
      @logger.info("user found: #{service.service_user_name} retrieving tweets...")
      since_id = nil
      count = 0
      tweets = nil
      begin
        tweets = retrieve_tweets(service)
      rescue => e
        retry_after = REFRESH_INTERVAL_EMPTY
        if e.to_s =~ /Retry After (\d+)/
          retry_after = $1
          @logger.info("throttled!  Retry after: #{retry_after}")
        else
          ErrorReport.log_exception(:processing, e, {
            :message => e.to_s,
            :url => (request.url rescue "none")
          })
          @logger.info("unexpected error: #{e.to_s} #{e.backtrace.join "\n"}")
        end
        retry_after = [REFRESH_INTERVAL_EMPTY, retry_after].max
        service.refresh_at = Time.now.utc + retry_after + 1.minute
        service.save
      end
      
      if tweets
        @logger.info("found #{tweets.length} tweets")
        tweets.each do |tweet|
          scans = (tweet['text'] || '').scan(/#([^#\s])/)
          @logger.info("message found: #{tweet['id']} with #{scans.length} hashtags")
          scans.each do |scan|
            hash = scan[0]
            if hashtag = Hashtag.find_by_hashtag(hash)
              hashtag.add_short_message(service.user, tweet, false)
              @logger.info("added for #{hash}")
            end
          end
          since_id ||= tweet['id'] if tweet['id']
        end
        service.last_result_id = since_id if since_id
        service.refresh_at = Time.now.utc + (since_id ? REFRESH_INTERVAL : REFRESH_INTERVAL_EMPTY)
        service.save
      end
    end
    
    if count >= MAX_PER_PROCESS
      @logger.info("more services to process... scheduling another job")
      TwitterUserPoller.send_later_engueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
    end
  end
end

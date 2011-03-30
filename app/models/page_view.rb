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

class PageView < ActiveRecord::Base
  set_primary_key 'request_id'

  belongs_to :developer_key
  belongs_to :user
  belongs_to :account
  
  before_save :ensure_account
  before_save :cap_interaction_seconds
  belongs_to :context, :polymorphic => true
  
  named_scope :of_account, lambda { |account|
    {
      :conditions => { :account_id => account.self_and_all_sub_accounts }
    }
  }
  
  attr_accessor :generated_by_hand
  attr_accessor :is_update
  
  def ensure_account
    self.account_id ||= (self.context_type == 'Account' ? self.context_id : self.context.account_id) rescue nil
    self.account_id ||= (self.context.is_a?(Account) ? self.context : self.context.account) if self.context
  end
  
  def interaction_seconds_readable
    time = (self.interaction_seconds || 0).to_i
    if time <= 10
      "--"
    elsif time < 60
      "#{time} secs"
    elsif time < 3600
      "#{time / 60} mins"
    else
      "#{time / 3600} hrs"
    end
  end
  
  def cap_interaction_seconds
    self.interaction_seconds = [self.interaction_seconds || 5, 10.minutes.to_i].min
  end
  
  def user_name
    self.user.name rescue "Unknown User"
  end
  
  def context_name
    self.context.name rescue ""
  end
  
  named_scope :recent_with_user, lambda {
    {:order => 'page_views.id DESC', :limit => 100, :include => :user}
  }
  named_scope :to_be_summarized, lambda {
    {:conditions => 'page_views.summarized IS NULL', :order => 'page_views.created_at', :limit => 1 }
  }
  named_scope :summarize_range, lambda {|context, start_at, end_at|
    {:conditions => ['page_views.context_id = ? AND page_views.context_type = ? AND page_views.created_at > ? AND page_views.created_at < ?', context.id, context.class.to_s, start_at.utc, end_at.utc] }
  }
  named_scope :after, lambda{ |date|
    {:conditions => ['page_views.created_at > ?', date] }
  }
  named_scope :for_user, lambda {|user_ids|
    {:conditions => {:user_id => user_ids} }
  }
  named_scope :limit, lambda {|limit| 
    {:limit => limit }
  }
  
  def generate_summaries
    self.summarized = true
    self.save
    hour_start = ActiveSupport::TimeWithZone.new(Time.utc(self.created_at.year, self.created_at.month, self.created_at.day, self.created_at.hour), Time.zone).utc
    hour_end = hour_start + (60*60)
    range = PageViewRange.find_or_create_by_context_id_and_context_type_and_start_at_and_end_at(self.context_id, self.context_type, hour_start, hour_end)
    range.re_summarize
    day_start = Time.utc(self.created_at.year, self.created_at.month, self.created_at.day)
    day_end = day_start + 1.day
    range = PageViewRange.find_or_create_by_context_id_and_context_type_and_start_at_and_end_at(self.context_id, self.context_type, day_start, day_end)
    range.re_summarize
  end

  def self.page_views_enabled?
    return false if Rails.env.test?
    !!page_view_method
  end

  def self.page_view_method
    enable_page_views = Setting.get_cached('enable_page_views', 'false')
    return false if enable_page_views == 'false'
    enable_page_views = 'db' if enable_page_views == 'true' # backwards compat
    enable_page_views.to_sym
  end

  def store
    case PageView.page_view_method
    when :log
      Rails.logger.info "PAGE VIEW: #{self.attributes.to_json}"
    when :cache
      begin
        json = self.attributes.as_json
        json['is_update'] = true if self.is_update
        Canvas.redis.rpush(PageView.cache_queue_name, json.to_json)
      rescue Errno::ECONNREFUSED
        # we're going to ignore the error for now, if redis is unavailable
      end
    when :db
      self.save
    end
  end

  def do_update(params = {})
    updated_at = params['updated_at'] || self.updated_at || Time.now
    updated_at = Time.parse(updated_at) if updated_at.is_a?(String)
    self.contributed ||= params['page_view_contributed'] || params['contributed']
    seconds = self.interaction_seconds || 0
    if params['interaction_seconds'].to_i > 0
      seconds += params['interaction_seconds'].to_i
    else
      seconds += [5, (Time.now - updated_at)].min
      seconds = [seconds, Time.now - created_at].min if created_at
    end
    self.updated_at = Time.now
    self.interaction_seconds = seconds
    self.is_update = true
  end

  def self.cache_queue_name
    'page_view_queue'
  end

  def self.process_cache_queue
    redis = Canvas.redis
    lock_key = 'page_view_queue_processing'
    # lock other processors out until we're done. if more than an hour
    # passes, the lock will be dropped and we'll assume this processor died.
    #
    # we're really being pessimistic here, there shouldn't ever be more than
    # one periodic job worker running anyway.
    unless redis.setnx lock_key, 1
      return
    end
    redis.expire lock_key, 1.hour

    begin
      # process as many items as were in the queue when we started.
      qlen = redis.llen(self.cache_queue_name)
      qlen.times do
        json = redis.lpop(self.cache_queue_name)
        break unless json
        attrs = JSON.parse(json)
        if attrs['is_update']
          page_view = self.find_by_request_id(attrs['request_id'])
          next unless page_view
          page_view.do_update(attrs)
          page_view.save
        else
          # request_id is primary key, so auto-protected from mass assignment
          request_id = attrs.delete('request_id')
          self.create(attrs) { |p| p.request_id = request_id }
        end
      end
    ensure
      redis.del lock_key
    end
  end
end

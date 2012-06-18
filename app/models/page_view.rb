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
  include TextHelper

  set_primary_key 'request_id'

  belongs_to :developer_key
  belongs_to :user
  belongs_to :account
  belongs_to :real_user, :class_name => 'User'
  belongs_to :asset_user_access

  before_save :ensure_account
  before_save :cap_interaction_seconds
  belongs_to :context, :polymorphic => true

  named_scope :of_account, lambda { |account|
    {
      :conditions => { :account_id => account.self_and_all_sub_accounts }
    }
  }
  named_scope :by_created_at, :order => 'created_at DESC'

  attr_accessor :generated_by_hand
  attr_accessor :is_update

  attr_accessible :url, :user, :controller, :action, :session_id, :developer_key, :user_agent, :real_user

  def ensure_account
    self.account_id ||= (self.context_type == 'Account' ? self.context_id : self.context.account_id) rescue nil
    self.account_id ||= (self.context.is_a?(Account) ? self.context : self.context.account) if self.context
  end

  def interaction_seconds_readable
    seconds = (self.interaction_seconds || 0).to_i
    if seconds <= 10
      t(:insignificant_duration, "--")
    else
      readable_duration(seconds)
    end
  end

  def cap_interaction_seconds
    self.interaction_seconds = [self.interaction_seconds || 5, 10.minutes.to_i].min
  end

  def user_name
    self.user.name rescue t(:default_user_name, "Unknown User")
  end

  def context_name
    self.context.name rescue ""
  end

  named_scope :after, lambda{ |date|
    {:conditions => ['page_views.created_at > ?', date] }
  }
  named_scope :for_user, lambda {|user_ids|
    {:conditions => {:user_id => user_ids} }
  }
  named_scope :limit, lambda {|limit|
    {:limit => limit }
  }

  def self.page_views_enabled?
    !!page_view_method
  end

  def self.page_view_method
    enable_page_views = Setting.get_cached('enable_page_views', 'false')
    return false if enable_page_views == 'false'
    enable_page_views = 'db' if enable_page_views == 'true' # backwards compat
    enable_page_views.to_sym
  end

  def store
    result = case PageView.page_view_method
    when :log
      Rails.logger.info "PAGE VIEW: #{self.attributes.to_json}"
    when :cache
      json = self.attributes.as_json
      json['is_update'] = true if self.is_update
      if Canvas.redis.rpush(PageView.cache_queue_name, json.to_json)
        true
      else
        # redis failed, push right to the db
        self.save
      end
    when :db
      self.save
    end

    if result
      self.created_at ||= Time.zone.now
      self.store_page_view_to_user_counts
    end

    result
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
    lock_key += ":#{Shard.current.description}" unless Shard.current.default?
    lock_time = Setting.get("page_view_queue_lock_time", 15.minutes.to_s).to_i

    # lock other processors out until we're done. if more than lock_time
    # passes, the lock will be dropped and we'll assume this processor died.
    unless redis.setnx lock_key, 1
      return
    end
    redis.expire lock_key, lock_time

    begin
      # process as many items as were in the queue when we started.
      todo = redis.llen(self.cache_queue_name)
      while todo > 0
        batch_size = [Setting.get_cached('page_view_queue_batch_size', '1000').to_i, todo].min
        redis.expire lock_key, lock_time
        transaction do
          process_cache_queue_batch(batch_size, redis)
        end
        todo -= batch_size
      end
    ensure
      redis.del lock_key
    end
  end

  def self.process_cache_queue_batch(batch_size, redis = Canvas.redis)
    batch_size.times do
      json = redis.lpop(self.cache_queue_name)
      break unless json
      attrs = JSON.parse(json)
      self.process_cache_queue_item(attrs)
    end
  end

  def self.process_cache_queue_item(attrs)
    return if attrs['is_update'] && Setting.get_cached('skip_pageview_updates', nil) == "true"
    self.transaction(:requires_new => true) do
      if attrs['is_update']
        page_view = self.find_by_request_id(attrs['request_id'])
        return unless page_view
        page_view.do_update(attrs)
        page_view.save
      else
        # bypass mass assignment protection
        self.create { |p| p.send(:attributes=, attrs, false) }
      end
    end
  rescue ActiveRecord::StatementInvalid => e
  end

  def self.user_count_bucket_for_time(time)
    utc = time.in_time_zone('UTC')
    # round down to the last 5 minute mark -- so 03:43:28 turns into 03:40:00
    utc = utc - ((utc.min % 5) * 60) - utc.sec
    "active_users:#{utc.as_json}"
  end

  def store_page_view_to_user_counts
    return unless Setting.get_cached('page_views_store_active_user_counts', 'false') == 'redis' && Canvas.redis_enabled?
    return unless self.created_at.present? && self.user.present?
    exptime = Setting.get_cached('page_views_active_user_exptime', 1.day.to_s).to_i
    bucket = PageView.user_count_bucket_for_time(self.created_at)
    Canvas.redis.sadd(bucket, self.user.global_id)
    Canvas.redis.expire(bucket, exptime)
  end
end

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
end

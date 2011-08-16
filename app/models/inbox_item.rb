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

class InboxItem < ActiveRecord::Base
  include Workflow
  belongs_to :user
  belongs_to :author, :class_name => 'User', :foreign_key => :sender_id
  belongs_to :asset, :polymorphic => true
  before_save :flag_changed
  before_save :infer_context_code
  after_save :update_user_inbox_items_count
  after_destroy :update_user_inbox_items_count

  attr_accessible :user_id, :asset, :subject, :body_teaser, :sender_id
  
  workflow do
    state :unread
    state :read
    state :deleted
    state :retired
    state :retired_unread
  end
  
  def infer_context_code
    self.context_code ||= self.asset.context_code rescue nil
    self.context_code ||= self.asset.context.asset_string rescue nil
  end
  
  def mark_as_read
    update_attribute(:workflow_state, 'read')
  end
  
  def sender_name
    User.cached_name(self.sender_id)
  end
  
  def context
    Context.find_by_asset_string(self.context_code) rescue nil
  end
  
  def context_short_name
    return unless self.context_code
    Rails.cache.fetch(['short_name_lookup', self.context_code].cache_key) do
      Context.find_by_asset_string(self.context_code).short_name rescue ""
    end
  end
  
  def flag_changed
    @item_state_changed = self.new_record? || self.workflow_state_changed?
    true
  end
  
  def update_user_inbox_items_count
    User.update_all({:unread_inbox_items_count => (self.user.inbox_items.unread.count rescue 0)}, {:id => self.user_id})
  end
  
  def context_type_plural
    self.context_code.split("_")[0..-2].join("_").pluralize
  end
  
  def context_id
    self.context_code.split("_").last.to_i rescue nil
  end
  
  def item_asset_string
    "#{self.asset_type.underscore}_#{self.asset_id}"
  end
  
  named_scope :active, :conditions => "workflow_state NOT IN ('deleted', 'retired', 'retired_unread')"
  named_scope :unread, lambda {
    {:conditions => ['workflow_state = ?', 'unread']}
  }
end

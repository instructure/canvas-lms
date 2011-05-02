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

class AccountUser < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  has_many :role_overrides, :as => :context
  has_many :all_account_courses, :class_name => 'Course', :foreign_key => 'root_account_id', :primary_key => 'account_id'
  has_a_broadcast_policy
  before_save :infer_defaults
  before_save :set_update_account_associations_if_changed
  after_save :touch_user
  after_save :update_account_associations_if_changed

  def set_update_account_associations_if_changed
    @should_update_account_associations = (self.account_id_changed? || self.user_id_changed?) && !self.user_id.nil?
    true
  end

  def update_account_associations_if_changed
    send_later_if_production(:update_account_associations) if @should_update_account_associations
  end

  def update_account_associations
    self.user.update_account_associations if self.user
  end

  def infer_defaults
    self.membership_type ||= 'AccountAdmin'
  end
  
  set_broadcast_policy do |p|
    p.dispatch :new_account_user
    p.to {|record| record.account.users}
    p.whenever {|record| record.just_created }
    
    p.dispatch :account_user_registration
    p.to {|record| record.user }
    p.whenever {|record| @account_user_registration }
    
    p.dispatch :account_user_notification
    p.to {|record| record.user }
    p.whenever {|record| @account_user_notification }
  end
  
  def readable_type
    AccountUser.readable_type(self.membership_type)
  end
  
  def account_user_registration!
    @account_user_registration = true
    self.save!
    @account_user_registration = false
  end
  
  def account_user_notification!
    @account_user_notification = true
    self.save!
    @account_user_notification = false
  end
  
  def has_permission_to?(action)
    @permission_lookup ||= {}
    @permission_lookup[action] ||= RoleOverride.permission_for(self, action, self.membership_type)[:enabled]
  end
  
  def self.readable_type(type)
    if type == 'AccountAdmin' || !type || type.empty?
      'Account Admin'
    else
      type
    end
  end
  
  def self.any_for?(user)
    !account_ids_for_user(user).empty?
  end
  
  def self.account_ids_for_user(user)
    @account_ids_for ||= {}
    @account_ids_for[user.id] ||= Rails.cache.fetch(['account_ids_for_user', user].cache_key) do
      AccountUser.for_user(user).map(&:account_id)
    end
  end
  
  def self.for_user_and_account?(user, account_id)
    account_ids_for_user(user).include?(account_id)
  end
  
  named_scope :for_user, lambda{|user|
    {:conditions => ['account_users.user_id = ?', user.id] }
  }
end

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
  has_a_broadcast_policy
  before_save :infer_defaults
  after_save :touch_user
  after_save :update_account_associations_if_changed
  attr_accessible :account, :user, :membership_type

  validates_presence_of :account_id, :user_id

  alias_method :context, :account

  BASE_ROLE_NAME = 'AccountMembership'

  def update_account_associations_if_changed
    if (self.account_id_changed? || self.user_id_changed?)
      if self.new_record?
        return if %w{creation_pending deleted}.include?(self.user.workflow_state)
        account_chain = self.account.account_chain
        associations = {}
        account_chain.each_with_index { |account, idx| associations[account.id] = idx }
        self.user.update_account_associations(:incremental => true, :precalculated_associations => associations)
      else
        self.user.update_account_associations_later
      end
    end
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
      t('types.account_admin', "Account Admin")
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

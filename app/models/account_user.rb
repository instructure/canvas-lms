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
  after_destroy :touch_user
  after_save :update_account_associations_if_changed
  after_destroy :update_account_associations_later
  attr_accessible :account, :user, :membership_type

  validates_presence_of :account_id, :user_id, :membership_type

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

  def update_account_associations_later
    self.user.update_account_associations_later
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

  def enabled_for?(context, action)
    @permission_lookup ||= {}
    @permission_lookup[[context.class, context.global_id, action]] ||= RoleOverride.enabled_for?(account, context, action, base_role_name, membership_type)
  end

  def has_permission_to?(context, action)
    enabled_for?(context, action).include?(:self)
  end

  def self.all_permissions_for(user, account)
    account_users = account.account_users_for(user)
    result = {}
    account_users.each do |account_user|
      RoleOverride.permissions.keys.each do |permission|
        result[permission] ||= []
        result[permission] |= account_user.enabled_for?(account, permission)
      end
    end
    result
  end

  def is_subset_of?(user)
    needed_permissions = RoleOverride.permissions.keys.inject({}) do |result, permission|
      result[permission] = enabled_for?(account, permission)
      result
    end
    target_permissions = AccountUser.all_permissions_for(user, account)
    needed_permissions.all? do |(permission, needed_permission)|
      next true unless needed_permission.present?
      target_permission = target_permissions[permission]
      next false unless target_permission.present?
      (needed_permission - target_permission).empty?
    end
  end

  def base_role_name
    BASE_ROLE_NAME
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
  
  scope :for_user, lambda { |user| where(:user_id => user) }
end

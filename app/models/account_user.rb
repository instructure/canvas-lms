#
# Copyright (C) 2011 - present Instructure, Inc.
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
  belongs_to :role
  include Role::AssociationHelper

  has_many :role_overrides, :as => :context, :inverse_of => :context
  has_a_broadcast_policy
  before_validation :infer_defaults
  after_save :touch_user
  after_destroy :touch_user
  after_save :update_account_associations_if_changed
  after_destroy :update_account_associations_later

  validate :valid_role?

  validates_presence_of :account_id, :user_id, :role_id

  alias_method :context, :account

  scope :active, -> { where.not(workflow_state: 'deleted') }

  include Workflow
  workflow do
    state :active

    state :deleted do
      event :reactivate, transitions_to: :active
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    return if self.new_record?
    self.workflow_state = 'deleted'
    self.save!
  end

  def update_account_associations_if_changed
    being_deleted = self.workflow_state == 'deleted' && self.workflow_state_before_last_save != 'deleted'
    if (self.saved_change_to_account_id? || self.saved_change_to_user_id?) || being_deleted
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
    self.role ||= Role.get_built_in_role('AccountAdmin')
  end

  def valid_role?
    return true if role.built_in?

    unless role.account_role?
      self.errors.add(:role_id, "is not a valid account role")
    end

    unless self.account.valid_role?(role)
      self.errors.add(:role_id, "is not an available role for this account")
    end
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

  set_policy do
    given { |user| self.account.grants_right?(user, :manage_account_memberships) && is_subset_of?(user) }
    can :create and can :destroy
  end

  def readable_type
    AccountUser.readable_type(self.role.name)
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
    @permission_lookup[[context.class, context.global_id, action]] ||= RoleOverride.enabled_for?(context, action, self.role, self.account)
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
    needed_permissions = RoleOverride.manageable_permissions(account).keys.inject({}) do |result, permission|
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
      AccountUser.active.for_user(user).map(&:account_id)
    end
  end

  def self.for_user_and_account?(user, account_id)
    account_ids_for_user(user).include?(account_id)
  end

  scope :for_user, lambda { |user| where(:user_id => user) }
end

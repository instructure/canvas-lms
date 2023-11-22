# frozen_string_literal: true

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
  extend RootAccountResolver

  belongs_to :account
  belongs_to :user
  belongs_to :role

  has_many :role_overrides, as: :context, inverse_of: :context
  has_a_broadcast_policy
  before_validation :infer_defaults
  after_save :clear_user_cache
  after_destroy :clear_user_cache
  after_save :update_account_associations_if_changed
  after_destroy :update_account_associations_later

  validate :valid_role?, unless: :deleted?
  validates :account_id, :user_id, :role_id, presence: true

  resolves_root_account through: :account
  include Role::AssociationHelper

  alias_method :context, :account

  scope :active, -> { where.not(workflow_state: "deleted") }
  scope :deleted, -> { where(workflow_state: "deleted") }

  include Workflow
  workflow do
    state :active

    state :deleted do
      event :reactivate, transitions_to: :active
    end
  end

  def clear_user_cache
    self.class.connection.after_transaction_commit do
      user.touch unless User.skip_touch_for_type?(:account_users)
      user.clear_cache_key(:account_users)
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    return if new_record?

    self.workflow_state = "deleted"
    save!
  end

  def update_account_associations_if_changed
    being_deleted = workflow_state == "deleted" && workflow_state_before_last_save != "deleted"
    being_undeleted = workflow_state == "active" && workflow_state_before_last_save == "deleted"
    if (saved_change_to_account_id? || saved_change_to_user_id?) || being_deleted || being_undeleted
      if new_record?
        return if %w[creation_pending deleted].include?(user.workflow_state)

        account_chain = account.account_chain
        associations = {}
        account_chain.each_with_index { |account, idx| associations[account.id] = idx }
        user.update_account_associations(incremental: true, precalculated_associations: associations)
      else
        user.update_account_associations_later
      end
    end
  end

  delegate :update_account_associations_later, to: :user

  def infer_defaults
    self.role ||= Role.get_built_in_role("AccountAdmin", root_account_id: account.resolved_root_account_id)
  end

  def valid_role?
    return true if role.built_in?

    unless role.account_role?
      errors.add(:role_id, "is not a valid account role")
    end

    unless account.valid_role?(role)
      errors.add(:role_id, "is not an available role for this account")
    end
  end

  set_broadcast_policy do |p|
    p.dispatch :new_account_user
    p.to { |record| record.account.users }
    p.whenever(&:just_created)

    p.dispatch :account_user_registration
    p.to(&:user)
    p.whenever { @account_user_registration }

    p.dispatch :account_user_notification
    p.to(&:user)
    p.whenever { @account_user_notification }
  end

  set_policy do
    # NOTE: If modifying this, make sure `create_permissions_cache` stays accurate as well.
    given { |user| account.grants_right?(user, :manage_account_memberships) && is_subset_of?(user) }
    can :create and can :destroy
  end

  def self.create_permissions_cache(account_users, current_user, session)
    # If we have a bunch of account_users that share the same account/role, we
    # don't need to lookup the permissions for all of them. Only one per
    # account/role to make things significantly faster.
    account_users.distinct.pluck(:account_id, :role_id).each_with_object({}) do |obj, hash|
      account_id, role_id = obj
      account_user = account_users.where(account_id:, role_id:).first

      # Create and destory are granted by the same conditions, no reason to do two
      # grants_right? checks here.
      permission = account_user.grants_right?(current_user, session, :destroy)
      hash[[account_id, role_id]] = { create: permission, destroy: permission }
      hash
    end
  end

  def readable_type
    AccountUser.readable_type(self.role.name)
  end

  def account_user_registration!
    @account_user_registration = true
    save!
    @account_user_registration = false
  end

  def account_user_notification!
    @account_user_notification = true
    save!
    @account_user_notification = false
  end

  def enabled_for?(context, action)
    @permission_lookup ||= {}
    @permission_lookup[[context.class, context.global_id, action]] ||= RoleOverride.enabled_for?(context, action, self.role, account)
  end

  def permission_check(context, action)
    enabled_for?(context, action).include?(:self) ? AdheresToPolicy::Success.instance : AdheresToPolicy::Failure.instance
  end

  def permitted_for_account?(_target_account)
    AdheresToPolicy::Success.instance
  end

  def self.all_permissions_for(user, account)
    account_users = account.cached_account_users_for(user)
    result = {}
    account_users.each do |account_user|
      RoleOverride.permissions.each_key do |permission|
        result[permission] ||= []
        result[permission] |= account_user.enabled_for?(account, permission)
      end
    end
    result
  end

  def self.is_subset_of?(user, account, role)
    needed_permissions = RoleOverride.manageable_permissions(account).keys.index_with do |permission|
      RoleOverride.enabled_for?(account, permission, role, account)
    end
    target_permissions = AccountUser.all_permissions_for(user, account)
    needed_permissions.all? do |(permission, needed_permission)|
      next true unless needed_permission.present?

      target_permission = target_permissions[permission]
      next false unless target_permission.present?

      (needed_permission - target_permission).empty?
    end
  end

  def is_subset_of?(user)
    AccountUser.is_subset_of?(user, account, role)
  end

  def self.readable_type(type)
    if type == "AccountAdmin" || !type || type.empty?
      t("types.account_admin", "Account Admin")
    else
      type
    end
  end

  def self.any_for?(user)
    !account_ids_for_user(user).empty?
  end

  def self.account_ids_for_user(user)
    @account_ids_for ||= {}
    @account_ids_for[user.id] ||= Rails.cache.fetch(["account_ids_for_user", user].cache_key) do
      AccountUser.active.for_user(user).map(&:account_id)
    end
  end

  def self.for_user_and_account?(user, account_id)
    account_ids_for_user(user).include?(account_id)
  end

  scope :for_user, ->(user) { where(user_id: user) }
end

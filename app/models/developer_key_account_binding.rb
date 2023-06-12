# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class DeveloperKeyAccountBinding < ApplicationRecord
  include Workflow
  workflow do
    state :off
    state :on
    state :allow
  end

  belongs_to :account
  belongs_to :developer_key
  belongs_to :root_account, class_name: "Account"

  validates :account, :developer_key, presence: true

  before_save :set_root_account
  after_update :clear_cache_if_site_admin
  after_update :update_tools!

  # Find a DeveloperKeyAccountBinding in order of accounts. The search for a binding will
  # be prioritized by the order of accounts. If a binding is found for the first account
  # that binding will be returned, otherwise the next account will be searched and so on.
  #
  # By default only bindings with a workflow set to “on” or “off” are considered. To include
  # bindings with workflow state “allow” set the explicitly_set parameter to false.
  #
  # For example consider four accounts with ids 1, 2, 3, and 4. Accounts 2, 3, and 4 have a binding
  # with the developer key. The workflow state of the binding for account 2 is "allow." The
  # workflow state of the binding for account 3 is "off." The workflow state of the binding for
  # account 4 is "on."
  #
  # find_in_account_priority([1, 2, 3, 4], developer_key.id) would return the binding for
  # account 3. Account 4 is not returned because it is after account 3 in the parameters.
  #
  # find_in_account_priority([1, 2, 3, 4], developer_key.id, false) would return the binding for
  # account 2.
  #
  # With a cross-shard account at some point in the account chain, bindings are searched for across
  # each shard of each account.
  def self.find_in_account_priority(accounts, developer_key, explicitly_set: true)
    bindings = Shard.partition_by_shard(accounts) do |accounts_by_shard|
      account_ids_string = "{#{accounts_by_shard.map(&:id).join(",")}}"
      relation = DeveloperKeyAccountBinding
                 .joins(sanitize_sql("JOIN unnest('#{account_ids_string}'::int8[]) WITH ordinality AS i (id, ord) ON i.id=account_id"))
                 .where(developer_key:)
                 .order(:ord)
      relation = relation.where.not(workflow_state: "allow") if explicitly_set
      relation.take
    end

    # Still need to order by priority -- if, given accounts [1,2,3], accounts 1
    # and 3 were on shard A and account 2 was on shard B, and accounts 2 and 3
    # had bindings, bindings.first would be for account 3
    accounts_to_index = accounts.map(&:global_id).each_with_index.to_a.to_h
    bindings.compact.min_by { |b| accounts_to_index[b.global_account_id] }
  end

  def self.find_site_admin_cached(developer_key)
    # Site admin bindings don't exists for non-site admin developer keys
    return nil if developer_key.account_id.present?

    Shard.default.activate do
      MultiCache.fetch(site_admin_cache_key(developer_key)) do
        GuardRail.activate(:secondary) do
          binding = where.not(workflow_state: "allow").find_by(
            account: Account.site_admin,
            developer_key:
          )
          binding
        end
      end
    end
  end

  def self.clear_site_admin_cache(developer_key)
    Shard.default.activate do
      MultiCache.delete(site_admin_cache_key(developer_key))
    end
  end

  def self.site_admin_cache_key(developer_key)
    "accounts/site_admin/developer_key_account_bindings/#{developer_key.global_id}"
  end

  alias_method :allowed?, :allow?

  private

  def set_root_account
    self.root_account_id ||= account&.resolved_root_account_id
  end

  def update_tools!
    if disable_tools?
      developer_key.disable_external_tools!(account)
    elsif enable_tools?
      developer_key.enable_external_tools!(account)
    elsif restore_tools?
      developer_key.restore_external_tools!(account)
    end
  end

  def enable_tools?
    saved_change_to_workflow_state? && on?
  end

  def disable_tools?
    saved_change_to_workflow_state? && off?
  end

  def restore_tools?
    saved_change_to_workflow_state? && allowed?
  end

  def clear_cache_if_site_admin
    self.class.clear_site_admin_cache(developer_key) if account.site_admin?
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class K5::EnablementService
  K5_SETTINGS = [:enable_as_k5_account, :use_classic_font_in_k5].freeze

  def initialize(account)
    @account = account
    @root_account = account.root_account
  end

  def set_k5_settings(enable_k5, use_classic_font)
    # Only tweak stuff if something has changed
    return if enable_k5 == @account.enable_as_k5_account? && use_classic_font == @account.use_classic_font_in_k5?

    # Lock enable_as_k5_account as ON down the inheritance chain once an account enables it
    # This is important in determining whether k5 mode dashboard is shown to a user
    @account.settings[:enable_as_k5_account] = {
      locked: enable_k5,
      value: enable_k5
    }

    # Add subaccount ids with k5 mode enabled to the root account's setting k5_accounts
    enable_k5 ? add_to_root_account_id_set(@account, :k5_accounts) : remove_from_root_account_id_set(@account, :k5_accounts)

    # Only allow setting font if k5 is on. If k5 is disabled, remove font settings.
    if enable_k5
      @account.settings[:use_classic_font_in_k5] = {
        locked: true,
        value: use_classic_font
      }
      use_classic_font ? add_to_root_account_id_set(@account, :k5_classic_font_accounts) : remove_from_root_account_id_set(@account, :k5_classic_font_accounts)
    else
      @account.settings.delete(:use_classic_font_in_k5)
      remove_from_root_account_id_set(@account, :k5_classic_font_accounts)
    end

    unset_font_in_descendent_accounts
    @root_account.save! unless @account.root_account?

    # Invalidate the cached k5 settings for all users in the account
    @account.root_account.clear_k5_cache
  end

  private

  def add_to_root_account_id_set(account, setting)
    account_ids = @root_account.settings[setting] || []
    account_ids = Set.new(account_ids)
    @root_account.settings[setting] = account_ids.add(account.id).to_a
  end

  def remove_from_root_account_id_set(account, setting)
    account_ids = @root_account.settings[setting] || []
    account_ids = Set.new(account_ids)
    @root_account.settings[setting] = account_ids.delete(account.id).to_a
  end

  def unset_font_in_descendent_accounts
    descendent_account_ids = Account.sub_account_ids_recursive(@account.id)
    k5_classic_font_account_ids = @root_account.settings[:k5_classic_font_accounts]
    affected_account_ids = descendent_account_ids & k5_classic_font_account_ids

    # there should only be 0 or 1 affected accounts since we remove font settings from descendents
    # each time a parent is updated, so there shouldn't be a way to accumulate multiple descendents
    # with font settings
    affected_account_ids.each do |id|
      subaccount = Account.find(id)
      subaccount.settings.delete(:use_classic_font_in_k5)
      subaccount.save!
      remove_from_root_account_id_set(subaccount, :k5_classic_font_accounts)
    end
  end
end

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
  def self.set_k5_settings(account, enable_k5)
    # Only tweak stuff if the k5 setting has changed
    unless enable_k5 == account.enable_as_k5_account?
      # Lock enable_as_k5_account as ON down the inheritance chain once an account enables it
      # This is important in determining whether k5 mode dashboard is shown to a user
      account.settings[:enable_as_k5_account] = {
        locked: enable_k5,
        value: enable_k5
      }
      account.save

      # Add subaccount ids with k5 mode enabled to the root account's setting k5_accounts
      if enable_k5
        add_to_root_account_id_set(account, :k5_accounts)
      else
        remove_from_root_account_id_set(account, :k5_accounts)
      end

      # Invalidate the cached k5 settings for all users in the account
      account.root_account.clear_k5_cache
    end
  end

  def self.add_to_root_account_id_set(account, setting)
    account_ids = account.root_account.settings[setting] || []
    account_ids = Set.new(account_ids)
    modify_root_account_id_set(account, setting, account_ids.add(account.id))
  end
  private_class_method :add_to_root_account_id_set

  def self.remove_from_root_account_id_set(account, setting)
    account_ids = account.root_account.settings[setting] || []
    account_ids = Set.new(account_ids)
    modify_root_account_id_set(account, setting, account_ids.delete(account.id))
  end
  private_class_method :remove_from_root_account_id_set

  def self.modify_root_account_id_set(account, setting, account_ids)
    account.root_account.settings[setting] = account_ids.to_a
    account.root_account.save!
  end
  private_class_method :modify_root_account_id_set
end

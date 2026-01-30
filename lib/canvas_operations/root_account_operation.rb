# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module CanvasOperations
  # RootAccountOperation
  #
  # Base class for operations that need to run in the context of a specific root account.
  #
  # This class extends BaseOperation and provides:
  #   - Automatic shard binding based on the root account's shard
  #   - Plugin setting context wrapping via PluginSetting.with_account
  #   - Unique singleton job keys per root account to allow concurrent execution across accounts
  #
  # Subclasses should override the `execute` method to implement their specific operation logic.
  #
  # Example:
  #   class MyAccountOperation < CanvasOperations::RootAccountOperation
  #     def execute
  #       # Your operation logic here, with access to @root_account
  #       log_message("Running operation for account #{root_account.global_id}")
  #     end
  #   end
  #
  #   # Usage:
  #   operation = MyAccountOperation.new(root_account: Account.find(123))
  #   operation.run_later
  class RootAccountOperation < BaseOperation
    attr_reader :root_account

    def initialize(root_account:)
      super(switchman_shard: root_account.shard)
      @root_account = root_account
    end

    # Override run_later to wrap execution in PluginSetting.with_account context.
    # This ensures that plugin settings are resolved in the context of the root account.
    def run_later
      PluginSetting.with_account(root_account) { super }
    end

    # Override singleton to include the root account's global ID.
    # This allows operations to run concurrently for different root accounts,
    # while ensuring only one operation per root account can be queued/running at a time.
    def singleton
      "shards/#{switchman_shard.id}/accounts/#{root_account.global_id}"
    end

    protected

    # Override context to use the root account as the Progress context
    def context
      @context ||= root_account
    end
  end
end

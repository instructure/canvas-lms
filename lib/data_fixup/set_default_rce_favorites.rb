# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup
  module SetDefaultRceFavorites
    # Every always_on tool (new name: on_by_default) should be added to Account favorites by default.
    # Users can turn them off in Settings / Apps.
    def self.run
      default_on_tools = ContextExternalTool.on_by_default_ids
      RequestCache.enable do
        Account.active.non_shadow.find_each do |account|
          ids = account.settings.dig(:rce_favorite_tool_ids, :value)
          # Subaccounts with a nil favorite list inherit favorites from their parent; we have nothing to do.
          next if ids.nil? && !account.root_account?

          # Default_on tools are created in the root account only and inherited by the subaccounts.
          root_account_id = if account.root_account?
                              account.global_id
                            else
                              account.global_root_account_id
                            end
          default_on_tool_ids = RequestCache.cache("default_on_tools_in_account", root_account_id) do
            ContextExternalTool.active.where(developer_key_id: default_on_tools, context_type: "Account", context_id: root_account_id).pluck(:id).map { |id| Shard.global_id_for(id) }
          end
          next if default_on_tool_ids.empty?

          ids ||= []
          ids |= default_on_tool_ids
          Rails.logger.info "account.global_id=#{account.global_id}, old rce_favorite_tool_ids: #{account.settings[:rce_favorite_tool_ids].inspect}"
          account.settings[:rce_favorite_tool_ids] = { value: ids }
          account.save!
        rescue => e
          Sentry.with_scope do |scope|
            scope.set_tags(account_id: account.global_id)
            scope.set_context("exception", { name: e.class.name, message: e.message })
            Sentry.capture_message("DataFixup#set_default_rce_favorites", level: :warning)
          end
        end
      end
    end
  end
end

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::CleanupCrossShardDeveloperKeys
  def self.run
    DeveloperKey.find_ids_in_ranges(batch_size: 100_000) do |min, max|
      self.send_later_if_production_enqueue_args(:delete_developer_keys_with_cross_shard_account_ids,
      {
        priority: Delayed::MAX_PRIORITY,
        n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
      },
      min, max)
    end
  end

  def self.delete_developer_keys_with_cross_shard_account_ids(min, max)
    DeveloperKey.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      ids = DeveloperKey.where(id: batch_min..batch_max).
        where("NOT EXISTS (?)", AccessToken.joins(:user).
          where("access_tokens.developer_key_id=developer_keys.id").
          where.not(users: {workflow_state: 'deleted'}).
          where("users.id < ?", Shard::IDS_PER_SHARD)).
        where("account_id > ?", Shard::IDS_PER_SHARD).
        pluck(:id)
      AccessToken.where(developer_key_id: ids).delete_all
      DeveloperKeyAccountBinding.where(developer_key_id: ids).delete_all
      cet_ids = ContextExternalTool.where(developer_key_id: ids).pluck(:id)
      # Stopped at ContentTag here because it kept going down a bit, and I thought maybe moving people's module items would be weird
      # Plus there shouldn't be any if the dev key is just a shard split artifact
      ContextExternalToolPlacement.where(context_external_tool_id: cet_ids).delete_all
      ContextExternalTool.where(id: cet_ids).delete_all
      Lti::ToolConfiguration.where(developer_key_id: ids).delete_all
      Lti::ToolConsumerProfile.where(developer_key_id: ids).delete_all
      DeveloperKey.where(id: ids).delete_all
    end
  end
end

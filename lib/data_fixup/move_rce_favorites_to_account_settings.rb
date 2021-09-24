# frozen_string_literal: true

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

module DataFixup::MoveRceFavoritesToAccountSettings
  def self.run
    Account.root_accounts.non_shadow.to_a.each do |root_account|
      next if root_account.settings[:rce_favorite_tool_ids]
      tool_ids = root_account.context_external_tools.active.where(:is_rce_favorite => true).pluck(:id).map{|id| Shard.global_id_for(id)}
      next unless tool_ids.any?
      root_account.settings[:rce_favorite_tool_ids] = {:value => tool_ids}
      root_account.save!
    end
  end
end

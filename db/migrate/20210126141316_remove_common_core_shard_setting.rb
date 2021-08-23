# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class RemoveCommonCoreShardSetting < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    return unless Shard.current == Shard.default

    Shard.where.not(settings: nil).find_each do |shard|
      shard.settings.delete(:common_core_outcome_group_id)
      shard.save! if shard.changed?
    end
  end
end

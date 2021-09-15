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

class RenameSwitchmanShardsPkeyIndex < ActiveRecord::Migration[6.0]
  tag :postdeploy

  def up
    # this index may be named differently depending on if you went through the
    # rename from shards => switchman_shards or not
    if index_name_exists?(:switchman_shards, :shards_pkey)
      rename_index :switchman_shards, :shards_pkey, :switchman_shards_pkey
    end
  end
end

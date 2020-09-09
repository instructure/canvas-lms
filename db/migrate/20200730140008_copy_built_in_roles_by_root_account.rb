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

# We will merge this only when we're ready for a batch of backfills to start
# otherwise, we can keep collecting. After we've merged once, when we have new models
# to run we can just copy this with a new migration ID and run it again

class CopyBuiltInRolesByRootAccount < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::CopyBuiltInRolesByRootAccount.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOW_PRIORITY,
      n_strand: ["built_in_roles_copy_fixup", Shard.current.database_server.id])
  end

  def down
  end
end

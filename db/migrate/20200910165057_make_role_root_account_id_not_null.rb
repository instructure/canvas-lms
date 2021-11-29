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

# We will merge this only when we're ready for a batch of backfills to start
# otherwise, we can keep collecting. After we've merged once, when we have new models
# to run we can just copy this with a new migration ID and run it again

class MakeRoleRootAccountIdNotNull < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    Role.where(:root_account_id => nil).update_all(:root_account_id => 0)
    change_column_null :roles, :root_account_id, false
  end

  def down
    change_column_null :roles, :root_account_id, true
  end
end

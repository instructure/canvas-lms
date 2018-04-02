#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AddAllowMembershipServiceAccessToContextExternalTool < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :context_external_tools, :allow_membership_service_access, :boolean
    change_column_default :context_external_tools, :allow_membership_service_access, false

    DataFixup::BackfillNulls.run(
      ContextExternalTool, [:allow_membership_service_access], default_value: false
    )

    change_column_null :context_external_tools, :allow_membership_service_access, false
  end

  def down
    remove_column :context_external_tools, :allow_membership_service_access, :boolean
  end
end

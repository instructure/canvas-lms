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

class AddIsRceFavoriteToContextExternalTools < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :context_external_tools, :is_rce_favorite, :boolean, if_not_exists: true
    change_column_default(:context_external_tools, :is_rce_favorite, false)
    DataFixup::BackfillNulls.run(ContextExternalTool, :is_rce_favorite, default_value: false)
    change_column_null(:context_external_tools, :is_rce_favorite, false)
  end
end

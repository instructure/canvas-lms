# frozen_string_literal: true

#
# Canvas is Copyright (C) 2024 - present Instructure, Inc.
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

class ContextExternalToolsNotSelectableNotNull < ActiveRecord::Migration[7.0]
  tag :postdeploy

  disable_ddl_transaction!

  def change
    DataFixup::BackfillNulls.run(ContextExternalTool, :not_selectable, batch_size: 10_000)
    change_column_null :context_external_tools, :not_selectable, false
  end
end

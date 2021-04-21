# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AddAllowIncludeParamsToDeveloperKey < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    add_column :developer_keys, :allow_includes, :boolean
    change_column_default(:developer_keys, :allow_includes, false)
    DataFixup::BackfillNulls.run(DeveloperKey, :allow_includes, default_value: false)
    change_column_null(:developer_keys, :allow_includes, false)
  end
end

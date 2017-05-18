#
# Copyright (C) 2015 - present Instructure, Inc.
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

class DropUnusedColumnsFromGroups < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :groups, :hashtag
    remove_column :groups, :show_public_context_messages
  end

  def down
    add_column :groups, :hashtag, :string
    add_column :groups, :show_public_context_messages, :boolean
  end
end

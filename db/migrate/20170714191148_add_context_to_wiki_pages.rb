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

class AddContextToWikiPages < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  tag :predeploy

  def change
    add_column :wiki_pages, :context_id, :integer, :limit => 8
    add_column :wiki_pages, :context_type, :string
    add_index :wiki_pages, [:context_id, :context_type], algorithm: :concurrently
  end
end

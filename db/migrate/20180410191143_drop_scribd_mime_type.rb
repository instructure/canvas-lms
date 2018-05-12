#
# Copyright (C) 2018 - present Instructure, Inc.
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

class DropScribdMimeType < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def up
    drop_table :scribd_mime_types
  end

  def down
    create_table "scribd_mime_types" do |t|
      t.string :extension, limit: 255
      t.string :name, limit: 255
      t.timestamps
    end
    add_index :scribd_mime_types, :extension, name: 'index_scribd_mime_types_on_extension'
  end
end

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class CreateCanvadocsTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :canvadocs do |t|
      t.string :document_id
      t.string :process_state
      t.integer :attachment_id, limit: 8, null: false
      t.timestamps null: true
    end
    add_index :canvadocs, :document_id, :unique => true
    add_index :canvadocs, :attachment_id
    add_index :canvadocs, :process_state
    add_foreign_key :canvadocs, :attachments
  end

  def self.down
    drop_table :canvadocs
  end
end

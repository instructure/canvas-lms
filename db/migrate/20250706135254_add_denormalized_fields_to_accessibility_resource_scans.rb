# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AddDenormalizedFieldsToAccessibilityResourceScans < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    change_table :accessibility_resource_scans, bulk: true do |t|
      t.string :resource_name, limit: 255, index: true
      t.string :resource_workflow_state, default: "unpublished", null: false, index: true
      t.integer :issue_count, default: 0, null: false, index: true
      t.timestamp :resource_updated_at, index: { where: "resource_updated_at IS NOT NULL" }
    end

    add_check_constraint :accessibility_resource_scans,
                         "resource_workflow_state IN ('unpublished', 'published')",
                         name: "chk_resource_workflow_state_enum"

    remove_index :accessibility_resource_scans, :wiki_page_id
    remove_index :accessibility_resource_scans, :assignment_id
    remove_index :accessibility_resource_scans, :attachment_id

    add_index :accessibility_resource_scans,
              :wiki_page_id,
              unique: true,
              where: "wiki_page_id IS NOT NULL"

    add_index :accessibility_resource_scans,
              :assignment_id,
              unique: true,
              where: "assignment_id IS NOT NULL"

    add_index :accessibility_resource_scans,
              :attachment_id,
              unique: true,
              where: "attachment_id IS NOT NULL"
  end
end

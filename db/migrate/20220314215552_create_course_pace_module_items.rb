# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CreateCoursePaceModuleItems < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    create_table :course_pace_module_items do |t|
      t.belongs_to :course_pace, foreign_key: true, index: true
      t.integer :duration, null: false, default: 0
      t.references :module_item, foreign_key: { to_table: :content_tags }
      t.references :root_account, foreign_key: { to_table: :accounts }, limit: 8, null: false, index: false
      t.timestamps
    end

    add_replica_identity "CoursePaceModuleItem", :root_account_id, 0
  end

  def down
    drop_table :course_pace_module_items
  end
end

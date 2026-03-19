# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

class RemoveNavTypeFromNavMenuLinks < ActiveRecord::Migration[8.0]
  tag :postdeploy

  def up
    # The default course_nav value was just set to ensure data migrated nicely
    change_column_default :nav_menu_links, :course_nav, from: true, to: false

    remove_index :nav_menu_links, %i[account_id nav_type workflow_state], where: "account_id IS NOT NULL"
    remove_index :nav_menu_links, %i[course_id nav_type workflow_state], where: "course_id IS NOT NULL"

    remove_check_constraint :nav_menu_links, name: "chk_nav_type_matches_context"
    remove_check_constraint :nav_menu_links, name: "chk_nav_type_enum"
    remove_column :nav_menu_links, :nav_type
  end

  def down
    add_column :nav_menu_links, :nav_type, :string, default: "course", null: false
    add_check_constraint :nav_menu_links,
                         "nav_type IN ('course', 'account', 'user')",
                         name: "chk_nav_type_enum"
    add_check_constraint :nav_menu_links,
                         "(nav_type = 'course') = (course_id IS NOT NULL)",
                         name: "chk_nav_type_matches_context"

    add_index :nav_menu_links, %i[account_id nav_type workflow_state], where: "account_id IS NOT NULL"
    add_index :nav_menu_links, %i[course_id nav_type workflow_state], where: "course_id IS NOT NULL"

    change_column_default :nav_menu_links, :course_nav, from: false, to: true
  end
end

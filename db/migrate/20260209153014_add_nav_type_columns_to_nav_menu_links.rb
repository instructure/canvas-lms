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

class AddNavTypeColumnsToNavMenuLinks < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    change_table :nav_menu_links, bulk: true do |t|
      t.change_default :nav_type, from: nil, to: "course"

      # Temporary set default to true to migrate old data. (Only course-nav links can be created in code so far)
      t.boolean :course_nav, default: true, null: false
      t.boolean :account_nav, default: false, null: false
      t.boolean :user_nav, default: false, null: false
    end

    add_check_constraint :nav_menu_links,
                         "(course_nav OR account_nav OR user_nav)",
                         name: "chk_at_least_one_nav_type"
    add_check_constraint :nav_menu_links,
                         "(course_id IS NULL) OR (account_nav = false AND user_nav = false)",
                         name: "chk_course_id_implies_only_course_nav"

    # Course-context links are all course-nav, so this index can be used for everything
    add_index :nav_menu_links,
              [:course_id, :workflow_state],
              where: "course_id IS NOT NULL",
              name: "index_course_id_and_workflow_state"

    add_index :nav_menu_links,
              %i[account_id workflow_state course_nav],
              where: "account_id IS NOT NULL",
              name: "index_account_id_and_workflow_state"

    # Given that there won't be that many account-context links, and tabs are cached,
    # it really isn't worth adding more indexes involving account_nav and user_nav
  end
end

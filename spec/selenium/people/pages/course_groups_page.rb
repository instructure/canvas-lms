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

class CourseGroups
  class << self
    include SeleniumDependencies

    # elements
    def visit_course_groups(course_id)
      get "/courses/#{course_id}/groups"
      make_full_screen
    end

    def groupset_actions_button(groupset_id)
      f("#group-category-#{groupset_id}-actions")
    end

    def randomly_assign_students_option
      f('a.randomly-assign-members')
    end

    def confirm_randomly_assign_students_button
      fj("button:contains('Okay')")
    end

    def group_detail_view_arrow_selector(group_name)
      fj("div .toggle-group[title='#{group_name}']")
    end

    def clone_groupset_name_input
      f("#cloned_category_name")
    end

    def group_settings_button(group_id)
      f("#group-#{group_id}-actions")
    end

    def delete_group_option
      f('a.delete-group')
    end

    def clone_category_submit_button
      f("#clone_category_submit_button")
    end

    def user_assign_to_group_button(user_id)
      fj("a[data-user-id='user_#{user_id}']")
    end

    def group_option_for_user_button(group_id)
      fj("a[data-group-id='#{group_id}']")
    end

    def unassigned_students_header
      f(".unassigned-users-heading")
    end

    def group_sets_tabs
      ff('.group-category-tab-link')
    end

    def all_users_in_group
      ff('.group-user-name')
    end

    def group_user_action_button(student_id)
      fj(".group-user-actions[data-user-id=user_#{student_id}]")
    end

    def edit_user_group(student_id)
      fj(".edit-group-assignment[data-user-id=user_#{student_id}]")
    end

    def move_to_group_option
      f(".move-select select")
    end

    def remove_student_from_group_menu
      fj("a:contains('Remove')")
    end

    def select_group_option_from_dropdown(group_name)
      fj("select option:contains('#{group_name}')")
    end

    def save_dropdown_selection_button
      f(".move-select button[type='submit']")
    end

    def groupset_tabs
      ff('.group-category-tab-link')
    end

    # methods and actions
    def toggle_group_detail_view(group_name)
      group_detail_view_arrow_selector(group_name).click
    end

    def move_unassigned_user_to_group(user_id, group_id=0)
      user_assign_to_group_button(user_id).click
      group_option_for_user_button(group_id).click
      wait_for_ajaximations
    end

    def move_student_to_different_group(student_id, curr_group_name, dest_group_name)
      toggle_group_detail_view(curr_group_name)
      group_user_action_button(student_id).click
      edit_user_group(student_id).click
      wait_for_ajaximations
      move_to_group_option.click
      select_group_option_from_dropdown(dest_group_name).click
      save_dropdown_selection_button.click
      wait_for_ajaximations
    end

    def clone_category_confirm
      wait_for_new_page_load(clone_category_submit_button.click)
    end

    def remove_student_from_group(student_id, curr_group_name)
      toggle_group_detail_view(curr_group_name)
      group_user_action_button(student_id).click
      remove_student_from_group_menu.click
      wait_for_ajaximations
    end

    def delete_group(group_id)
      group_settings_button(group_id).click
      delete_group_option.click
      accept_alert
      wait_for_animations
    end

    def randomly_assign_students_for_set(groupset_id)
      groupset_actions_button(groupset_id).click
      randomly_assign_students_option.click
      confirm_randomly_assign_students_button.click
      wait_for_ajaximations
    end
  end
end

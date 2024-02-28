# frozen_string_literal: true

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
#

require_relative "../helpers/manage_groups_common"
describe "manage groups" do
  include_context "in-process server selenium tests"
  include ManageGroupsCommon

  before do
    course_with_teacher_logged_in
  end

  context "2.0" do
    describe "group category creation" do
      it "auto-splits students into groups" do
        groups_student_enrollment 4
        get "/courses/#{@course.id}/groups"
        f("#add-group-set").click
        f("#new-group-set-name").send_keys("zomg")
        f('[data-testid="group-structure-selector"]').click
        f('[data-testid="group-structure-num-groups"]').click
        f('[data-testid="split-groups"]').send_keys("2")
        f(%(button[data-testid="group-set-save"])).click
        run_jobs
        wait_for_ajaximations
        expect(GroupCategory.last.name).to eq "zomg"
        expect(Group.last(2).pluck(:name)).to match_array ["zomg 1", "zomg 2"]
      end
    end

    it "allows a teacher to create a group set, a group, and add a user" do
      course_with_teacher_logged_in(active_all: true)
      student_in_course
      student_in_course

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      f("#add-group-set").click
      wait_for_animations
      replace_and_proceed f("#new-group-set-name"), "Group Set 1"
      f(%(button[data-testid="group-set-save"])).click
      wait_for_ajaximations

      # verify the group set tab is created
      expect(fj("#group_categories_tabs li[role='tab']:nth-child(2)").text).to eq "Group Set 1"
      # verify has the two created but unassigned students
      expect(ff("div[data-view='unassignedUsers'] .group-user-name").length).to eq 2

      # click the first visible "Add Group" button
      fj(".add-group:visible:first").click
      wait_for_animations
      f("#group_name").send_keys("New Test Group A")
      submit_form("span[aria-label='Add Group']")
      wait_for_ajaximations

      # Add user to the group
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
      wait_for_animations
      ff(".assign-to-group-menu .set-group").first.click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "1 student"
      expect(ff("div[data-view='unassignedUsers'] .assign-to-group").length).to eq 1

      # Remove added user from the group
      fj(".groups .group .toggle-group:first").click
      wait_for_ajaximations
      fj("[data-testid=groupUserMenu]:first").click
      wait_for_ajaximations
      f("[data-testid=removeFromGroup]").click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      # should re-appear in unassigned
      expect(ff("div[data-view='unassignedUsers'] .assign-to-group").length).to eq 2
    end

    it "allows a teacher to drag and drop a student among groups" do
      groups_student_enrollment 5
      group_categories = create_categories(@course, 1)
      groups = add_groups_in_category(group_categories[0])
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      # expand groups
      expand_group(groups[0].id)
      expand_group(groups[1].id)

      unassigned_group_selector = ".unassigned-students"
      group1_selector = ".group[data-id=\"#{groups[0].id}\"]"
      group2_selector = ".group[data-id=\"#{groups[1].id}\"]"
      group_user_selector = ".group-user"
      first_group_user_selector = ".group-user:first"

      first_unassigned_user = "#{unassigned_group_selector} #{first_group_user_selector}"
      first_group1_user = "#{group1_selector} #{first_group_user_selector}"

      unassigned_users_selector = "#{unassigned_group_selector} #{group_user_selector}"
      group1_users_selector = "#{group1_selector} #{group_user_selector}"
      group2_users_selector = "#{group2_selector} #{group_user_selector}"

      # assert all 5 students are in unassigned
      expect(ff(unassigned_users_selector).size).to eq 5
      expect(f("#content")).not_to contain_css(group1_users_selector)
      expect(f("#content")).not_to contain_css(group2_users_selector)

      drag_and_drop_element(fj(first_unassigned_user), fj(group1_selector))
      drag_and_drop_element(fj(first_unassigned_user), fj(group1_selector))
      # assert there are 3 students in unassigned
      # assert there is 2 student in group 0
      # assert there is still 0 students in group 1
      expect(ff(unassigned_users_selector).size).to eq 3
      expect(ff(group1_users_selector).size).to eq 2
      expect(f("#content")).not_to contain_css(group2_users_selector)

      drag_and_drop_element(fj(first_group1_user), fj(unassigned_group_selector))
      drag_and_drop_element(fj(first_group1_user), fj(group2_selector))
      # assert there are 4 students in unassigned
      # assert there are 0 students in group 0
      # assert there is 1 student in group 1
      expect(ff(unassigned_users_selector).size).to eq 4
      expect(f("#content")).not_to contain_css(group1_users_selector)
      expect(ff(group2_users_selector).size).to eq 1
    end

    it "supports student-organized groups" do
      course_with_teacher_logged_in(active_all: true)
      student_in_course
      student_in_course

      cat = GroupCategory.student_organized_for(@course)
      add_groups_in_category cat, 1

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css(".group-category-actions .al-trigger") # can't edit/delete etc.

      # user never leaves "Everyone" list, only gets added to a group once
      2.times do
        expect(f(".unassigned-users-heading").text).to eq "Everyone (2)"
        ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
        wait_for_animations
        ff(".assign-to-group-menu .set-group").first.click
        wait_for_ajaximations
        expect(fj(".group-summary:visible:first").text).to eq "1 student"
      end
    end

    it "allows a teacher to reassign a student with an accessible modal dialog" do
      groups_student_enrollment 2
      group_categories = create_categories(@course, 1)
      groups = add_groups_in_category(group_categories[0], 2)
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      # expand groups
      expand_group(groups[0].id)
      expand_group(groups[1].id)

      # Add an unassigned user to the first group
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
      wait_for_animations
      ff(".assign-to-group-menu .set-group").first.click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "1 student"
      expect(fj(".group-summary:visible:last").text).to eq "0 students"

      # Move the user from one group into the other
      f("[data-testid=groupUserMenu]").click
      f("[data-testid=moveTo]").click
      f("div[aria-label='Move Student']") # wait for element
      f(".move-select .move-select__group option:last-child").click
      expect(f("body")).to contain_jqcss(".move-select button[type='submit']:visible")
      f(".move-select button[type='submit']").click
      # wait for tray to not exist
      keep_trying_until { element_exists?("div[aria-label='Move Student']") == false }
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      expect(fj(".group-summary:visible:last").text).to eq "1 student"

      # Move the user back
      f("[data-testid=groupUserMenu]").click
      f("[data-testid=moveTo]").click
      f("div[aria-label='Move Student']") # wait for element
      ff(".move-select .move-select__group option").last.click
      expect(f("body")).to contain_jqcss(".move-select button[type='submit']:visible")
      f(".move-select button[type='submit']").click
      # wait for tray to not exist
      keep_trying_until { element_exists?("div[aria-label='Move Student']") == false }
      expect(fj(".group-summary:visible:first").text).to eq "1 student"
      expect(fj(".group-summary:visible:last").text).to eq "0 students"
    end

    it "gives a teacher the option to assign unassigned students to groups" do
      group_category, _ = create_categories(@course, 1)
      group, _ = add_groups_in_category(group_category, 1)
      student_in_course
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      actions_button = "#group-category-#{group_category.id}-actions"
      message_users = ".al-options .message-all-unassigned"
      randomly_assign_users = ".al-options .randomly-assign-members"

      # category menu should show unassigned-member options
      fj(actions_button).click
      wait_for_ajaximations
      expect(fj([actions_button, message_users].join(" + "))).to be
      expect(fj([actions_button, randomly_assign_users].join(" + "))).to be
      fj(actions_button).click # close the menu, or it can prevent the next step

      # assign the last unassigned member
      draggable_user = fj(".unassigned-students .group-user:first")
      droppable_group = fj(".group[data-id=\"#{group.id}\"]")
      drag_and_drop_element draggable_user, droppable_group
      wait_for_ajaximations

      # now the menu should not show unassigned-member options
      fj(actions_button).click
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css([actions_button, message_users].join(" + "))
      expect(f("#content")).not_to contain_css([actions_button, randomly_assign_users].join(" + "))
    end
  end

  it "lets students create groups and invite other users" do
    course_with_student_logged_in(active_all: true)
    student_in_course(course: @course, active_all: true, name: "other student")
    other_student = @student

    get "/courses/#{@course.id}/groups"
    f('button[data-testid="add-group-button"]').click
    wait_for_ajaximations
    f("#group-name").send_keys("group name")
    click_option("#join-level-select", "invitation_only", :value)
    f("#invite-filter").click
    f("#invite-filter").send_keys(:arrow_down, :return)
    wait_for_ajaximations

    f('button[type="submit"]').click
    wait_for_ajaximations
    new_group = @course.groups.first
    expect(new_group.name).to eq "group name"
    expect(new_group.join_level).to eq "invitation_only"
    expect(new_group.users).to include(other_student)
  end
end

# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/groups_common"
require_relative "../../selenium/people/pages/course_groups_page"

describe "new groups" do
  include_context "in-process server selenium tests"
  include GroupsCommon

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
    end

    it "allows teachers to add a group set", priority: "1" do
      get "/courses/#{@course.id}/groups"
      click_add_group_set
      replace_and_proceed f("#new-group-set-name"), "Test Group Set"
      f(%(button[data-testid="group-set-save"])).click

      wait_for(method: nil, timeout: 3) { f("#group_categories_tabs .collectionViewItems").displayed? }
      # Looks in the group tab list for the last item, which should be the group set
      expect(fj(".collectionViewItems[role=tablist]>li:last-child").text).to match "Test Group Set"
    end

    it "allows teachers to create groups within group sets", priority: "1" do
      seed_groups(1, 0)

      get "/courses/#{@course.id}/groups"

      expect(f(".btn.add-group")).to be_displayed
      f(".btn.add-group").click
      wait_for_ajaximations
      f("#group_name").send_keys("Test Group")
      submit_form("span[aria-label='Add Group']")
      wait_for_ajaximations
      expect(fj(".collectionViewItems.unstyled.groups-list>li:last-child")).to include_text("Test Group")
    end

    it "allows teachers to add a student to a group", priority: "1" do
      # Creates one user, and one groupset with a group inside it
      group_test_setup(1, 1, 1)

      get "/courses/#{@course.id}/groups"

      # Tests the list of groups in the + button menu popup to see if it has the correct groups
      f(".assign-to-group").click
      wait_for_ajaximations
      setgroup = f(".set-group")
      expect(setgroup).to include_text(@testgroup[0].name)
      setgroup.click
      wait_for_ajaximations

      # Adds student to test group and then expands the group display to the right to verify he is in the group
      f(".toggle-group").click
      wait_for_ajaximations
      expect(f(".group-summary")).to include_text("1 student")
      expect(f(".group-user-name")).to include_text(@students.first.name)
    end

    it "allows teachers to move a student to a different group", priority: "1" do
      # Creates 1 user, 1 groupset, and 2 groups within the groupset
      group_test_setup(1, 1, 2)
      # Add seeded student to first seeded group
      add_user_to_group(@students.first, @testgroup[0])

      get "/courses/#{@course.id}/groups"

      # Toggles the first group collapse arrow to see the student
      fj('.toggle-group :contains("Test Group 1")').click
      wait_for_ajaximations

      # Verifies the student is in their group
      expect(f(".group-user")).to include_text(@students[0].name)

      # Moves the student
      f("[data-testid=groupUserMenu").click
      wait_for_ajaximations
      f("[data-testid=moveTo").click
      wait_for_ajaximations
      click_option(".move-select .move-select__group select", @testgroup[1].name.to_s)
      button = f('.move-select button[type="submit"]')
      keep_trying_until do
        button.click
        true
      end
      wait_for_ajaximations

      # Verifies the student count updates
      expect(ff(".group-summary")[1]).to include_text("1 student")

      # Verifies student is within new group
      fj('.toggle-group :contains("Test Group 2")').click
      wait_for_ajaximations
      expect(f(".group-user")).to include_text(@students.first.name)
    end

    it "allows teachers to remove a student from a group", priority: "1" do
      group_test_setup
      add_user_to_group(@students.first, @testgroup[0])

      get "/courses/#{@course.id}/groups"

      f(".toggle-group").click
      wait_for_ajaximations

      remove_student_from_group

      expect(f(".ui-cnvs-scrollable")).to include_text(@students.first.name)
      expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (1)")
      expect(f(".group-summary")).to include_text("0 students")
    end

    it "does not allow teachers to see sections specific dropdown on announcement page" do
      group_test_setup
      get "/groups/#{@testgroup.first.id}/discussion_topics/new?is_announcement=true"
      expect(f("#sections_autocomplete_root").text).to eq ""
    end

    it "allows teachers to make a student a group leader", priority: "1" do
      group_test_setup
      add_user_to_group(@students.first, @testgroup[0])

      get "/courses/#{@course.id}/groups"

      fj('.toggle-group :contains("Test Group 1")').click
      wait_for_ajaximations

      # Sets user as group leader
      f("[data-testid=groupUserMenu]").click
      wait_for_ajaximations
      f("[data-testid=setAsLeader]").click
      wait_for_ajaximations

      # Looks for student to have a group leader icon
      expect(f(".group-leader .icon-user")).to be_displayed
      # Verifies group leader silhouette and leader's name appear in the group header
      expect(f(".span3.ellipsis.group-leader")).to be_displayed
      expect(f(".span3.ellipsis.group-leader")).to include_text(@students.first.name)

      check_element_has_focus f("[data-userid='#{@students.first.id}']")
    end

    it "allows teachers to message unassigned students" do
      group_test_setup

      get "/courses/#{@course.id}/groups"
      f(".icon-more").click
      wait_for_animations
      f(".message-all-unassigned").click
      replace_content(f("#message_all_unassigned"), "blah blah blah students")
      f('button[type="submit"]').click
      wait_for_ajaximations

      expect(@course).to eq Conversation.last.context
    end

    it "allows a teacher to set up a group set with member limits", priority: "1" do
      group_test_setup(3, 0, 0)
      get "/courses/#{@course.id}/groups"

      click_add_group_set
      replace_and_proceed f("#new-group-set-name"), "Test Group Set"
      fxpath("//input[@data-testid='checkbox-allow-self-signup']/..").click
      force_click('[data-testid="group-member-limit"]')
      f('[data-testid="group-member-limit"]').send_keys("2")
      f(%(button[data-testid="group-set-save"])).click
      wait_for_ajaximations

      expect(f(".group-category-summary")).to include_text("Groups are limited to 2 members.")

      # Creates a group and checks to see if group set's limit is inherited by its groups
      manually_create_group
      expect(f(".group-summary")).to include_text("0 / 2 students")
    end

    it "updates student count when they're added to groups limited by group set", priority: "1" do
      seed_students(3)
      @category = create_category(has_max_membership: true, member_limit: 3)
      @group = @course.groups.create!(name: "test group", group_category: @category)

      get "/courses/#{@course.id}/groups"

      expect(f(".group-summary")).to include_text("0 / 3 students")
      f(".al-trigger.btn").click

      # the randomly assign members option doesn't appear immediately and can result
      # in selenium clicking the wrong link. wait for it to appear before clicking
      # edit category to work around the issue
      wait_for(method: nil, timeout: 2) { f(".randomly-assign-members").displayed? }

      f(".icon-edit.edit-category").click

      replace_content(fj('input[name="group_limit"]:visible'), "2")
      f(".btn.btn-primary[type=submit]").click
      wait_for_ajaximations
      expect(f(".group-summary")).to include_text("0 / 2 students")
      manually_fill_limited_group("2", 2)
    end

    it "allows a teacher to set up a group with member limits", priority: "1" do
      group_test_setup(3, 1, 0)
      get "/courses/#{@course.id}/groups"

      manually_create_group(has_max_membership: true, member_limit: 2)
      expect(f(".group-summary")).to include_text("0 / 2 students")
    end

    it "Allows teacher to join students to groups in unpublished courses", priority: "1" do
      skip "FOO-4220" # TODO: re-enable this test (or rewrite) after fixing FOO-4263
      group_test_setup(3, 1, 2)
      @course.workflow_state = "unpublished"
      @course.save!
      get "/courses/#{@course.id}/groups"
      @group_category.first.update_attribute(:group_limit, 2)
      2.times do |n|
        add_user_to_group(@students[n], @testgroup[0], false)
      end
      add_user_to_group(@students.last, @testgroup[1], false)
      get "/courses/#{@course.id}/groups"
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).to be_displayed
      ff(".group-name")[0].click
      ff(".group-user-actions")[0].click
      fln("Set as Leader").click
      wait_for_ajaximations
      f(".group-user-actions[data-user-id=\"user_#{@students[0].id}\"]").click
      wait_for_ajaximations

      # the remove as leader option doesn't appear immediately and can result
      # in selenium clicking the wrong link. wait for it to appear before clicking
      # "Move To" to work around the issue
      wait_for(method: nil, timeout: 2) { f(".ui-menu-item .remove-as-leader").displayed? }

      f(".ui-menu-item .edit-group-assignment").click
      wait_for(method: nil, timeout: 2) { fxpath("//*[@data-cid='Tray']//*[@role='dialog']").displayed? }
      ff(".move-select .move-select__group option").last.click
      f('.move-select button[type="submit"]').click
      wait_for_ajaximations
      f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click
      expect(f("#content")).not_to contain_css(".group-leader .icon-user")
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] .group-user")).to include_text("Test Student 1")
    end

    it "updates student count when they're added to groups limited by group", priority: "1" do
      group_test_setup(3, 1, 0)
      create_group(group_category: @group_category.first, has_max_membership: true, member_limit: 2)
      get "/courses/#{@course.id}/groups"

      expect(f(".group-summary")).to include_text("0 / 2 students")
      manually_fill_limited_group("2", 2)
    end

    it "shows the FULL icon moving from one group to the next", priority: "1" do
      group_test_setup(4, 1, 2)
      @group_category.first.update_attribute(:group_limit, 2)

      2.times do |n|
        add_user_to_group(@students[n], @testgroup.first, false)
      end

      add_user_to_group(@students.last, @testgroup[1], false)
      get "/courses/#{@course.id}/groups"

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).to be_displayed
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] span.show-group-full")).not_to be_displayed

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      fj("[data-testid=groupUserMenu][data-userid=#{@students[0].id}]").click
      wait_for_ajaximations

      f("[data-testid=moveTo]").click
      wait_for_ajaximations

      f(".move-select .move-select__group") # fixes flakiness since the ff below doesn't wait for the element to appear
      ff(".move-select .move-select__group option").last.click
      wait_for_ajaximations

      button = f('.move-select button[type="submit"]')
      # have to wait for instUI animations
      keep_trying_until do
        button.click
        true
      end
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).not_to be_displayed
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] span.show-group-full")).to be_displayed
    end

    it "removes a student from a group and update the group status", priority: "1" do
      group_test_setup(4, 1, 2)
      @group_category.first.update_attribute(:group_limit, 2)

      2.times do |n|
        add_user_to_group(@students[n], @testgroup.first, false)
      end

      add_user_to_group(@students.last, @testgroup[1], false)
      get "/courses/#{@course.id}/groups"

      expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (1)")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("2 / 2 students")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).to be_displayed

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      fj("[data-testid=groupUserMenu][data-userid=#{@students[0].id}]").click
      wait_for_ajaximations

      f("[data-testid=removeFromGroup]").click
      wait_for_ajaximations

      expect(f(".ui-cnvs-scrollable")).to include_text(@students[0].name)
      expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (2)")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("1 / 2 students")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full").css_value("display")).to eq "none"
    end

    it "moves group leader", priority: "1" do
      group_test_setup(4, 1, 2)
      add_user_to_group(@students[0], @testgroup.first, true)
      2.times do |n|
        add_user_to_group(@students[n + 1], @testgroup.first, false)
      end
      get "/courses/#{@course.id}/groups"

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations
      fj("[data-testid=groupUserMenu][data-userid=#{@students[0].id}]").click
      wait_for_ajaximations
      f("[data-testid=moveTo]").click
      wait_for(method: nil, timeout: 2) { fxpath("//*[@data-cid='Tray']//*[@role='dialog']").displayed? }
      ff(".move-select .move-select__group option").last.click
      f('.move-select button[type="submit"]').click
      wait_for_ajaximations

      f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click

      expect(f("#content")).not_to contain_css(".group-leader .icon-user")
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] .group-user")).to include_text("Test Student 1")
    end

    it "moves non-leader", priority: "1" do
      skip_if_chrome("research")
      group_test_setup(4, 1, 2)
      add_user_to_group(@students[0], @testgroup.first, true)
      2.times do |n|
        add_user_to_group(@students[n + 1], @testgroup.first, false)
      end
      add_user_to_group(@students[3], @testgroup.last, false)

      get "/courses/#{@course.id}/groups"

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click

      expect(f(".group-leader .icon-user")).to be_displayed

      f(".group-user-actions[data-user-id=\"user_#{@students[1].id}\"]").click

      f(".ui-menu-item .edit-group-assignment").click
      wait_for_ajaximations

      click_option(".move-select .move-select__group select", @testgroup[1].id.to_s, :value)
      wait_for_ajaximations
      f('.move-select button[type="submit"]').click
      wait_for_ajaximations

      f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-user")).to include_text("Test Student 1")
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] .group-user")).to include_text("Test Student 2")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-leader")).to be_displayed
      expect(f("#content")).not_to contain_css(".group[data-id=\"#{@testgroup[1].id}\"] .group-leader")
    end

    it "removes group leader", priority: "1" do
      group_test_setup(4, 1, 2)
      add_user_to_group(@students[0], @testgroup.first, true)
      2.times do |n|
        add_user_to_group(@students[n + 1], @testgroup.first, false)
      end
      add_user_to_group(@students[3], @testgroup.last, false)

      get "/courses/#{@course.id}/groups"

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-user")).to include_text("Test Student 1")
      expect(f(".group-leader .icon-user")).to be_displayed

      fj("[data-testid=groupUserMenu][data-userid=#{@students[0].id}]").click
      wait_for_ajaximations
      f("[data-testid=removeFromGroup]").click
      wait_for_ajaximations

      get "/courses/#{@course.id}/groups"

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations
      f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-user")).not_to include_text("Test Student 1")
      expect(f("#content")).not_to contain_css(".row-fluid .group-leader")
    end

    it "splits students into groups automatically", priority: "1" do
      skip "FOO-3807 (10/7/2023)"
      seed_students(4)

      get "/courses/#{@course.id}/groups"

      click_add_group_set
      replace_and_proceed f("#new-group-set-name"), "Test Group Set"

      force_click('[data-testid="group-structure-selector"]')
      force_click('[data-testid="group-structure-num-groups"]')

      expect(f('span[data-testid="group-leadership-controls"] input[data-testid="first"]')).not_to be_enabled
      expect(f('span[data-testid="group-leadership-controls"] input[data-testid="random"]')).not_to be_enabled

      fxpath("//span[@data-testid='group-leadership-controls']//input[@data-testid='enable-auto']/..").click

      expect(f('span[data-testid="group-leadership-controls"] input[data-testid="first"]')).to be_enabled
      expect(f('span[data-testid="group-leadership-controls"] input[data-testid="random"]')).to be_enabled

      force_click('[data-testid="split-groups"]')

      f('[data-testid="split-groups"]').send_keys("2")
      f(%(button[data-testid="group-set-save"])).click
      # Need to run delayed jobs for the random group assignments to work, and then refresh the page
      run_jobs
      get "/courses/#{@course.id}/groups"
      2.times do |n|
        expect(ffj(".toggle-group.group-summary:visible")[n]).to include_text("2 students")
      end
      expect(ffj(".group-name:visible").size).to eq 2
    end

    it "auto-splits students into groups by section" do
      skip "FOO-3807 (10/7/2023)"
      course = Course.create!(name: "Group by section")

      course.enroll_teacher(@teacher)

      course.course_sections.create!(name: "section 1")
      course.course_sections.create!(name: "section 2")
      course.course_sections.create!(name: "section 3")

      s1 = User.create!(name: "First Student")
      s2 = User.create!(name: "Second Student")
      s3 = User.create!(name: "Third Student")
      s4 = User.create!(name: "Fourth Student")
      s5 = User.create!(name: "Fifth Student")

      course.course_sections[0].enroll_user(s1, "StudentEnrollment")
      course.course_sections[1].enroll_user(s2, "StudentEnrollment")
      course.course_sections[2].enroll_user(s3, "StudentEnrollment")
      course.course_sections[2].enroll_user(s4, "StudentEnrollment")
      course.course_sections[2].enroll_user(s5, "StudentEnrollment")

      Enrollment.last(6).each { |e| e.update!(workflow_state: "active") }

      get "/courses/#{course.id}/groups"

      f("#add-group-set").click
      replace_and_proceed f("#new-group-set-name"), "auto_split"
      force_click('[data-testid="group-structure-selector"]')
      force_click('[data-testid="group-structure-num-groups"]')
      f('[data-testid="split-groups"]').send_keys("3")
      force_click(%(input[data-testid="require-same-section-auto-assign"]))
      f(%(button[data-testid="group-set-save"])).click
      run_jobs
      wait_for_ajaximations
      expect(GroupCategory.last.name).to eq "auto_split"
      expect(Group.last(3).pluck(:name)).to match_array ["auto_split 1", "auto_split 2", "auto_split 3"]
      expect(Group.last(3).map(&:members_count)).to match_array [3, 1, 1]
    end

    it "respects individual group member limits when randomly assigning", priority: "1" do
      group_test_setup(16, 1, 2)
      @testgroup.first.update_attribute(:max_membership, 7)
      get "/courses/#{@course.id}/groups"

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("0 / 7 students")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full").css_value("display")).to eq "none"

      f("a.al-trigger.btn").click
      wait_for_ajaximations
      f(".icon-user.randomly-assign-members.ui-corner-all").click
      wait_for_ajaximations
      f("button.btn.btn-primary.randomly-assign-members-confirm").click
      wait_for_ajaximations

      # Run delayed jobs for randomly assigning students to the groups
      run_jobs

      get "/courses/#{@course.id}/groups"

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("7 / 7 students")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).to be_displayed
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] span.show-group-full").css_value("display")).to eq "none"
    end

    it "adds students via drag and drop", priority: "1" do
      group_test_setup(2, 1, 2)
      get "/courses/#{@course.id}/groups"

      drag_item1 = '.group-user-name:contains("Test Student 1")'
      drag_item2 = '.group-user-name:contains("Test Student 2")'
      drop_target1 = '.group:contains("Test Group 1")'

      drag_and_drop_element(fj(drag_item1), fj(drop_target1))
      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("1 student")

      drag_and_drop_element(fj(drag_item2), fj(drop_target1))
      wait_for_ajaximations

      group_to_check = ff(".group .group-user .group-user-name")
      expect(group_to_check[0]).to include_text("Test Student 1")
      expect(group_to_check[1]).to include_text("Test Student 2")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("2 students")
    end

    it "moves student using drag and drop", priority: "1" do
      group_test_setup(2, 1, 2)
      add_user_to_group(@students[0], @testgroup.first, false)
      add_user_to_group(@students[1], @testgroup.last, false)

      drag_item1 = '.group-user-name:contains("Test Student 2")'
      drop_target1 = '.group:contains("Test Group 1")'

      get "/courses/#{@course.id}/groups"
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("1 student")
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] .group-summary")).to include_text("1 student")

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      # click opens the group to display details, wait for it to complete
      expect(fj('.group-user-name:contains("Test Student 1")')).to be_displayed

      f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click
      # click opens the group to display details, wait for it to complete
      expect(fj('.group-user-name:contains("Test Student 2")')).to be_displayed

      drag_and_drop_element(fj(drag_item1), fj(drop_target1))
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("2 students")
      expect(f(".group[data-id=\"#{@testgroup[1].id}\"] .group-summary")).to include_text("0 students")
    end

    it "removes student using drag and drop", priority: "1" do
      group_test_setup(1, 1, 1)
      add_user_to_group(@students[0], @testgroup.first, false)

      drag_item1 = '.group-user-name:contains("Test Student 1")'
      drop_target1 = ".ui-cnvs-scrollable"

      get "/courses/#{@course.id}/groups"

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("1 student")
      expect(fj(".unassigned-users-heading.group-heading")).to include_text("Unassigned Students (0)")

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      drag_and_drop_element(fj(drag_item1), fj(drop_target1))
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("0 students")
      expect(fj(drop_target1)).to include_text("Test Student 1")
      expect(fj(".unassigned-users-heading.group-heading")).to include_text("Unassigned Students (1)")
    end

    it "changes group limit status with student drag and drop", priority: "1" do
      group_test_setup(5, 1, 1)
      @group_category.first.update_attribute(:group_limit, 5)
      5.times do |n|
        add_user_to_group(@students[n], @testgroup.first, false)
      end

      drag_item1 = '.group-user-name:contains("Test Student 3")'
      drop_target1 = ".ui-cnvs-scrollable"

      get "/courses/#{@course.id}/groups"

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("5 / 5 students")
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full")).to be_displayed
      expect(fj(".unassigned-users-heading.group-heading")).to include_text("Unassigned Students (0)")

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      wait_for_ajaximations

      drag_and_drop_element(fj(drag_item1), fj(drop_target1))
      wait_for_ajaximations

      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] span.show-group-full").css_value("display")).to eq "none"
      expect(f(".group[data-id=\"#{@testgroup[0].id}\"] .group-summary")).to include_text("4 / 5 students")
      expect(fj(".unassigned-users-heading.group-heading")).to include_text("Unassigned Students (1)")
      expect(fj(drop_target1)).to include_text("Test Student 3")
    end

    it "moves leader via drag and drop", priority: "1" do
      group_test_setup(5, 1, 2)
      2.times do |n|
        add_user_to_group(@students[n], @testgroup.first, false)
        add_user_to_group(@students[n + 2], @testgroup.last, false)
      end
      add_user_to_group(@students[4], @testgroup.last, true)

      get "/courses/#{@course.id}/groups"

      drag_item1 = '.group-user-name:contains("Test Student 5")'
      drop_target1 = ".group[data-id=\"#{@testgroup[0].id}\"]"

      f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
      # click opens the group to display details, wait for it to complete
      expect(fj('.group-user-name:contains("Test Student 2")')).to be_displayed

      f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click
      # click opens the second group, wait for it to complete
      expect(f(".group-leader .icon-user")).to be_displayed

      drag_and_drop_element(fj(drag_item1), fj(drop_target1))
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css(".group-leader .icon-user")
      expect(fj(drop_target1)).to include_text("Test Student 5")
    end

    context "using clone group set modal" do
      it "clones a group set including its groups and memberships" do
        skip("KNO-185")
        group_test_setup(2, 1, 2)
        add_user_to_group(@students.first, @testgroup[0], true)

        get "/courses/#{@course.id}/groups"

        manually_enable_self_signup
        replace_and_proceed f("#textinput-limit-group-size"), "2"
        f(%(button[data-testid="group-set-save"])).click
        wait_for_ajaximations

        open_clone_group_set_option
        set_cloned_groupset_name(@group_category.first.name + " clone", true)

        expect(ff(".group-category-tab-link").last.text).to match @group_category.first.name + " clone"

        ff(".group-category-tab-link").last.click
        wait_for_ajaximations

        # Scope of cloned group set
        group_set_clone = fj("#group_categories_tabs > div:last > .group-category-contents > .row-fluid")
        group1_clone = fj(".groups > div:last > .collectionViewItems > li:first", group_set_clone)
        group2_clone = fj(".groups > div:last > .collectionViewItems > li:last", group_set_clone)

        # Verifies group leader's name appears in group header of cloned group set
        expect(ffj(".group-leader", group_set_clone).first).to include_text(@students.first.name)

        # Verifies groups and their counts within the cloned group set
        expect(fj(".unassigned-students", group_set_clone)).to include_text("Unassigned Students (1)")
        expect(group1_clone).to include_text("1 / 2 students")
        expect(group2_clone).to include_text("0 / 2 students")

        # Toggles the first group collapse arrow to see the student
        fj(".row-fluid > .group-header > .span5 > .toggle-group", group1_clone).click
        wait_for_ajaximations

        # Verifies group membership within the cloned group set
        expect(fj(".group-users", group1_clone)).to include_text(@students.first.name)
      end

      it "alerts group set name is required and is already in use" do
        skip("KNO-186")
        group_test_setup

        get "/courses/#{@course.id}/groups"

        open_clone_group_set_option
        set_cloned_groupset_name("")

        # Verifies error text
        expect(f(".errorBox:not(#error_box_template)")).to include_text("Name is required")

        set_cloned_groupset_name(@group_category.first.name)

        # Verifies error text
        expect(f(".errorBox:not(#error_box_template)")).to include_text(@group_category.first.name + " is already in use.")
      end

      it "changes group membership after an assignment has been deleted" do
        group_test_setup
        add_user_to_group(@students.first, @testgroup[0])

        create_and_submit_assignment_from_group(@students.first)

        get "/courses/#{@course.id}/assignments"

        # Deletes assignment
        f(".ig-admin .al-trigger").click
        wait_for_ajaximations
        f(".delete_assignment").click

        driver.switch_to.alert.accept
        wait_for_animations

        get "/courses/#{@course.id}/groups"

        toggle_group_collapse_arrow

        remove_student_from_group

        # Verifies the unassigned students membership and count
        expect(f(".ui-cnvs-scrollable")).to include_text(@students.first.name)
        expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (1)")
      end

      context "choosing New Group Set option" do
        it "clones group set when adding an unassigned student to a group with submission" do
          group_test_setup(2, 1, 1)
          add_user_to_group(@students.last, @testgroup.first)
          create_and_submit_assignment_from_group(@students.last)

          CourseGroups.visit_course_groups(@course.id)
          CourseGroups.move_unassigned_user_to_group(@students.first.id, @testgroup.first.id)
          CourseGroups.clone_category_confirm

          # Verifies student has not changed groups and there is a new groupset tab
          expect(CourseGroups.unassigned_students_header).to include_text("Unassigned Students (1)")
          expect(CourseGroups.all_users_in_group.first.text).to eq @students.first.name
          expect(CourseGroups.groupset_tabs.count).to eq 2
        end

        it "clones group set when moving a student from a group to a group with submission" do
          group_test_setup(2, 1, 2)
          # add second student to second test group
          add_user_to_group(@students.last, @testgroup.last)
          # make a submission for second student
          create_and_submit_assignment_from_group(@students.last)

          CourseGroups.visit_course_groups(@course.id)
          # move unassigned first-student to first test group
          CourseGroups.move_unassigned_user_to_group(@students.first.id, @testgroup.first.id)
          # Moves Student1 from first test group to second test group
          CourseGroups.move_student_to_different_group(@students.first.id, @testgroup.first.name, @testgroup.last.name)
          CourseGroups.clone_category_confirm
          CourseGroups.toggle_group_detail_view(@testgroup.first.name)

          # Verifies student has not changed groups and there is a new groupset tab
          expect(CourseGroups.all_users_in_group.first.text).to eq @students.first.name
          expect(CourseGroups.groupset_tabs.count).to eq 2
        end

        it "clones group set when moving a student from a group with submission to a group" do
          group_test_setup(2, 1, 2)
          add_user_to_group(@students.last, @testgroup.last)
          create_and_submit_assignment_from_group(@students.last)

          CourseGroups.visit_course_groups(@course.id)
          # move unassigned first-student to first test group
          CourseGroups.move_unassigned_user_to_group(@students.first.id, @testgroup.first.id)
          # Moves student from Test Group 2 to Test Group 1
          CourseGroups.move_student_to_different_group(@students.last.id, @testgroup.last.name, @testgroup.first.name)
          CourseGroups.clone_category_confirm
          # Toggles the second group collapse arrow to see the student
          CourseGroups.toggle_group_detail_view(@testgroup.last.name)

          # Verifies student has not changed groups and there is a new groupset tab
          expect(CourseGroups.all_users_in_group.first.text).to eq @students.last.name
          expect(CourseGroups.groupset_tabs.count).to eq 2
        end

        it "clones group set when deleting a group with submission" do
          skip("KNO-187")
          group_test_setup
          add_user_to_group(@students.first, @testgroup.first)
          create_and_submit_assignment_from_group(@students.first)

          CourseGroups.visit_course_groups(@course.id)
          CourseGroups.delete_group(@testgroup.first.id)
          CourseGroups.clone_category_confirm
          CourseGroups.toggle_group_detail_view(@testgroup.first.name)

          # Verifies student has not changed groups and there is a new groupset tab
          expect(CourseGroups.all_users_in_group.first.text).to eq @students.first.name
          expect(CourseGroups.groupset_tabs.count).to eq 2
        end

        it "clones group set when using randomly assign students option when group has submission" do
          group_test_setup(2, 1, 1)
          add_user_to_group(@students.last, @testgroup.first)
          create_and_submit_assignment_from_group(@students.last)

          CourseGroups.visit_course_groups(@course.id)
          CourseGroups.randomly_assign_students_for_set(@group_category.first.id)
          CourseGroups.clone_category_confirm

          # Verifies student has not changed groups and there is a new groupset tab
          expect(CourseGroups.all_users_in_group.first.text).to eq @students.first.name
          expect(CourseGroups.unassigned_students_header).to include_text("Unassigned Students (1)")
          expect(CourseGroups.groupset_tabs.count).to eq 2
        end

        context "dragging and dropping a student" do
          it "clones group set when moving an unassigned student to a group with submission" do
            group_test_setup(2, 1, 1)
            add_user_to_group(@students.last, @testgroup[0])

            create_and_submit_assignment_from_group(@students.last)

            get "/courses/#{@course.id}/groups"

            @cloned_group_set_name = @group_category.first.name + " clone"

            toggle_group_collapse_arrow

            # Moves unassigned student to Test Group 1
            drag_and_drop_element(f(".unassigned-students .group-user"), f(".toggle-group"))
            wait_for_ajaximations

            set_cloned_groupset_name(@cloned_group_set_name, true)

            # Verifies student has not changed groups in group set
            expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (1)")
            expect(f(".group-user-name")).to include_text @students.first.name

            expect(fj(".collectionViewItems[role=tablist]>li:last-child").text).to match @cloned_group_set_name
          end

          it "clones group set when moving a student from a group to a group with submission" do
            group_test_setup(2, 1, 2)
            add_user_to_group(@students.last, @testgroup[1])

            create_and_submit_assignment_from_group(@students.last)

            get "/courses/#{@course.id}/groups"

            @cloned_group_set_name = @group_category.first.name + " clone"

            move_unassigned_student_to_group

            toggle_group_collapse_arrow

            # Moves student from Test Group 1 to Test Group 2
            drag_and_drop_element(ff(".group-users .group-user").first, ff(".toggle-group .group-name").last)
            wait_for_ajaximations

            set_cloned_groupset_name(@cloned_group_set_name, true)

            toggle_group_collapse_arrow

            # Verifies student has not changed groups
            expect(f(".group-user-name")).to include_text @students.first.name

            expect(fj(".collectionViewItems[role=tablist]>li:last-child").text).to match @cloned_group_set_name
          end

          it "clones group set when moving a student from a group with submission to a group" do
            group_test_setup(2, 1, 2)
            add_user_to_group(@students.last, @testgroup[0])

            create_and_submit_assignment_from_group(@students.last)

            get "/courses/#{@course.id}/groups"

            @cloned_group_set_name = @group_category.first.name + " clone"

            toggle_group_collapse_arrow

            move_unassigned_student_to_group(1)

            # Moves student from Test Group 1 to Test Group 2
            drag_and_drop_element(ff(".group-users .group-user").first, ff(".toggle-group .group-name").last)
            wait_for_ajaximations

            set_cloned_groupset_name(@cloned_group_set_name, true)

            toggle_group_collapse_arrow

            # Verifies student has not changed groups
            expect(f(".group-user-name")).to include_text @students.last.name

            expect(fj(".collectionViewItems[role=tablist]>li:last-child").text).to match @cloned_group_set_name
          end

          it "clones group set when moving a student from a group to unassigned students" do
            group_test_setup
            add_user_to_group(@students.first, @testgroup[0])

            create_and_submit_assignment_from_group(@students.first)

            get "/courses/#{@course.id}/groups"

            @cloned_group_set_name = @group_category.first.name + " clone"

            toggle_group_collapse_arrow

            # Moves student from Test Group 1 to Unassigned Students
            drag_and_drop_element(ff(".group-users .group-user").first, f(".ui-cnvs-scrollable"))
            wait_for_ajaximations

            set_cloned_groupset_name(@cloned_group_set_name, true)

            toggle_group_collapse_arrow

            # Verifies student has not changed groups
            expect(f(".group-user-name")).to include_text @students.first.name

            expect(fj(".collectionViewItems[role=tablist]>li:last-child").text).to match @cloned_group_set_name
          end
        end
      end

      context "choosing Change Groups option" do
        it "changes group membership when an assignment has been submitted by a group" do
          group_test_setup(2, 1, 2)
          add_user_to_group(@students.last, @testgroup[0])

          create_and_submit_assignment_from_group(@students.last)

          get "/courses/#{@course.id}/groups"
          move_unassigned_student_to_group

          select_change_groups_option

          toggle_group_collapse_arrow

          # Verifies the group count updates
          expect(f(".group-summary")).to include_text("2 students")

          # Verifies the group membership
          expect(f(".group-users .group-user-name")).to include_text @students.first.name

          # Moves Test User 2 to Test Group 2
          move_student_to_group(1, 1)

          select_change_groups_option

          # Toggles the first group collapse arrow to close group
          toggle_group_collapse_arrow

          # Toggles the second group collapse arrow to see student
          ff(".toggle-group .group-name").last.click
          wait_for_ajaximations

          # Verifies the group count updates
          expect(ff(".group-summary").last).to include_text("1 student")

          # Verifies the group membership
          expect(ff(".group-users").last).to include_text @students.last.name

          # Moves Test User 2 to Test Group 1
          ff("[data-testid=groupUserMenu]").last.click
          wait_for_ajaximations
          f("[data-testid=moveTo]").click
          wait_for(method: nil, timeout: 2) { fxpath("//*[@data-cid='Tray']//*[@role='dialog']").displayed? }
          click_option(".move-select .move-select__group select", @testgroup.first.name.to_s)

          sleep 0.3 # have to wait for instUI animations
          ff('.move-select button[type="submit"]').last.click

          wait_for_ajaximations

          select_change_groups_option

          # Toggles the second group collapse arrow to close group
          ff(".toggle-group .group-name").last.click
          wait_for_ajaximations

          # Toggles the first group collapse arrow to see student
          toggle_group_collapse_arrow

          # Verifies the group count updates
          expect(ff(".group-summary").first).to include_text("2 students")

          # Verifies the group membership
          expect(ff(".group-users").first).to include_text @students.first.name
          expect(ff(".group-users").first).to include_text @students.last.name

          # Removes Test User 2 from Test Group 1
          remove_student_from_group(1)

          select_change_groups_option

          # Verifies the group count updates
          expect(ff(".group-summary").first).to include_text("1 student")
          expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (1)")

          # Verifies the group membership
          expect(ff(".group-users").first).to include_text @students.first.name
          expect(f(".ui-cnvs-scrollable")).to include_text(@students.last.name)

          # Deletes a group with submission
          manually_delete_group

          select_change_groups_option

          # Verifies the group count updates
          expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (2)")

          # Verfies the group membership
          expect(f(".ui-cnvs-scrollable")).to include_text @students.first.name
          expect(f(".ui-cnvs-scrollable")).to include_text(@students.last.name)
        end

        it "changes group membership when using randomly assign students option when group has submission" do
          group_test_setup(2, 1, 1)
          add_user_to_group(@students.first, @testgroup[0])

          create_and_submit_assignment_from_group(@students.first)

          get "/courses/#{@course.id}/groups"

          select_randomly_assign_students_option

          select_change_groups_option

          expect(f(".progress-container")).to be_displayed
        end

        context "dragging and dropping a student" do
          it "changes group membership when an assignment has been submitted by a group" do
            group_test_setup(2, 1, 2)
            add_user_to_group(@students.last, @testgroup[0])

            create_and_submit_assignment_from_group(@students.last)

            get "/courses/#{@course.id}/groups"

            # Moves unassigned student to Test Group 1
            drag_and_drop_element(f(".unassigned-students .group-user"), f(".toggle-group"))
            wait_for_ajaximations

            select_change_groups_option

            toggle_group_collapse_arrow

            # Verifies the group count updates
            expect(f(".group-summary")).to include_text("2 students")

            # Verifies the group membership
            expect(f(".group-users .group-user-name")).to include_text @students.first.name

            # Moves Test User 2 to Test Group 2
            drag_and_drop_element(ff(".group-users .group-user").last, ff(".toggle-group .group-name").last)
            wait_for_ajaximations

            select_change_groups_option

            # Toggles the first group collapse arrow to close group
            toggle_group_collapse_arrow

            # Toggles the second group collapse arrow to see student
            ff(".toggle-group .group-name").last.click
            wait_for_ajaximations

            # Verifies the group count updates
            expect(ff(".group-summary").last).to include_text("1 student")

            # Verifies the group membership
            expect(ff(".group-users").last).to include_text @students.last.name

            # Moves Test User 2 to Test Group 1
            drag_and_drop_element(ff(".group-users .group-user").last, ff(".toggle-group .group-name").first)
            wait_for_ajaximations

            select_change_groups_option

            # Toggles the second group collapse arrow to close group
            ff(".toggle-group .group-name").last.click
            wait_for_ajaximations

            # Toggles the first group collapse arrow to see student
            toggle_group_collapse_arrow

            # Verifies the group count updates
            expect(ff(".group-summary").first).to include_text("2 students")

            # Verifies the group membership
            expect(ff(".group-users").first).to include_text @students.first.name
            expect(ff(".group-users").first).to include_text @students.last.name

            # Moves Test User 2 to unassigned students
            drag_and_drop_element(ff(".group-users .group-user").last, f(".ui-cnvs-scrollable"))
            wait_for_ajaximations

            select_change_groups_option

            # Verifies the usnassigned students membership
            expect(f(".ui-cnvs-scrollable")).to include_text(@students.last.name)

            # Verifies the group count updates
            expect(f(".unassigned-users-heading")).to include_text("Unassigned Students (1)")
          end
        end
      end
    end
  end

  context "manage groups permissions as a teacher" do
    before { course_with_teacher_logged_in }

    it "does not allow adding a group set if they don't have the permission" do
      @course.root_account.disable_feature!(:granular_permissions_manage_groups)
      @course.account.role_overrides.create!(permission: :manage_groups, role: teacher_role, enabled: false)

      get "/courses/#{@course.id}/groups"

      expect(f(".ic-Layout-contentMain")).not_to contain_css("button[title='Add Group Set']")
    end

    it "does not allow add/import group or group-set without :manage_groups_add (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      @course.account.role_overrides.create!(
        permission: "manage_groups_add",
        role: teacher_role,
        enabled: false
      )

      create_category
      get "/courses/#{@course.id}/groups"

      expect(f(".ic-Layout-contentMain")).not_to contain_css("button[title='Add Group Set']")
      expect(f(".ic-Layout-contentMain")).not_to contain_css("button[title='Import']")
      expect(f(".ic-Layout-contentMain")).not_to contain_css("button[title='Add Group']")
    end

    it "allows add/import group or group-set with :manage_groups_add (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)

      create_category
      get "/courses/#{@course.id}/groups"

      expect(f(".ic-Layout-contentMain")).to contain_css("button[title='Add Group Set']")
      expect(f(".ic-Layout-contentMain")).to contain_css("button[title='Import']")
      expect(f(".ic-Layout-contentMain")).to contain_css("button[title='Add Group']")
    end

    it "allows editing individual course-level groups" do
      gc = @course.group_categories.create!(name: "Course Groups")
      group = Group.create!(name: "group", group_category: gc, context: @course)

      get "/courses/#{@course.id}/groups"

      f("#group-#{group.id}-actions").click
      expect(f(".al-options")).to contain_css("a.icon-edit")
    end

    it "allows editing individual course-level groups (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      gc = @course.group_categories.create!(name: "Course Groups")
      group = Group.create!(name: "group", group_category: gc, context: @course)

      get "/courses/#{@course.id}/groups"

      f("#group-#{group.id}-actions").click
      expect(f(".al-options")).to contain_css("a.icon-edit")
    end

    it "does not allow editing individual course-level groups (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      @course.account.role_overrides.create!(
        permission: "manage_groups_manage",
        role: teacher_role,
        enabled: false
      )
      gc = @course.group_categories.create!(name: "Course Groups")
      group = Group.create!(name: "group", group_category: gc, context: @course)

      get "/courses/#{@course.id}/groups"

      f("#group-#{group.id}-actions").click
      expect(f(".al-options")).not_to contain_css("a.icon-edit")
    end
  end
end

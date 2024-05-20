# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "student groups" do
  include_context "in-process server selenium tests"
  include GroupsCommon

  let(:group_name) { "Windfury" }
  let(:group_category_name) { "cat1" }

  def wait_for_spinner(&)
    wait_for_transient_element(".spinner-container", &)
  end
  describe "as a student" do
    before do
      course_with_student_logged_in(active_all: true)
    end

    it "allows student group leaders to edit the group name", priority: "1" do
      category1 = @course.group_categories.create!(name: "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(name: "some group", group_category: category1)

      g1.add_user @student
      g1.leader = @student
      g1.save!

      get "/groups/#{g1.id}"

      f("#edit_group").click
      set_value f("#group_name"), "new group name"
      expect_new_page_load { submit_form("span[aria-label='Edit Group']") }
      expect(g1.reload.name).to include("new group name")
    end

    it "shows locked student organized, invite only groups", priority: "1" do
      @course.groups.create!(name: "my group")
      get "/courses/#{@course.id}/groups"

      expect(f(".icon-lock")).to be_displayed
    end

    it "restricts students from accessing groups in unpublished course", priority: "1" do
      group_test_setup(1, 1, 1)
      add_user_to_group(@students.first, @testgroup[0])
      @course.workflow_state = "unpublished"
      @course.save!
      user_session(@students.first)
      get "/courses/#{@course.id}/groups"
      expect(f("#unauthorized_message")).to be_displayed
    end

    describe "new student group" do
      before do
        seed_students(2)
        get "/courses/#{@course.id}/groups"
        f('button[data-testid="add-group-button"]').click
        wait_for_ajaximations
      end

      it "has dropdown with two options", priority: "2" do
        f("#join-level-select").click
        expect(ff("span[role='option']").length).to eq 2
        expect(f("#parent_context_auto_join")).to include_text("Course members are free to join")
        expect(f("#invitation_only")).to include_text("Membership by invitation only")
      end

      it "shows students in the course", priority: "1" do
        expected_student_list = ["Test Student 1", "Test Student 2"]
        f("#invite-filter").click
        student_list = ff("span[role='option']")
        # there should be no teachers in the list
        expect(student_list).to have_size(expected_student_list.size)
        # check the list of students for expected names
        expect(student_list[0].text).to eq "Test Student 1"
        expect(student_list[1].text).to eq "Test Student 2"
      end

      it "is titled what the user types in", priority: "1" do
        create_default_student_group(group_name)

        expect(fj(".student-group-title")).to include_text(group_name.to_s)
      end

      it "by default, created student group only contains the student creator", priority: "2" do
        create_default_student_group

        # expand the group
        fj(".student-group-title").click
        wait_for_ajaximations

        # first item in the array is the group name
        students = ff("[role=listitem]")
        expect(students.length).to eq 2
        expect(students[1]).to include_text("nobody@example.com")
      end

      it "adds students to the group", priority: "1" do
        create_group_and_add_all_students

        # expand the group
        fj(".student-group-title").click
        wait_for_ajaximations

        expected_student_list = ["nobody@example.com",
                                 "Test Student 1",
                                 "Test Student 2",
                                 "Test Student 3",
                                 "Test Student 4",
                                 "Test Student 5"]
        student_list = ff("[role=listitem]")

        # first item in the student_list array is the group name
        # I skip the group name and then do an index-1 to account for skipping index 0
        student_list.each_with_index do |student, index|
          if index != 0
            expect(student).to include_text(expected_student_list[index - 1].to_s)
          end
        end
      end
    end

    describe "new self sign-up groups" do
      it "allows a student to leave a group and not change the group leader", priority: "1" do
        # Creating two groups, using one, and ensuring the second group remains empty
        group_test_setup(4, 1, 2)
        @group_category.first.configure_self_signup(true, false)
        3.times do |n|
          add_user_to_group(@students[n], @testgroup.first, false)
        end
        add_user_to_group(@students[3], @testgroup.first, true)

        user_session(@students[0])
        get "/courses/#{@course.id}/groups"

        f(".student-group-header .icon-mini-arrow-right").click
        wait_for_ajaximations

        expect(f('div[role="list"]')).to include_text(@students[0].name.to_s)

        # First student leaves group
        fj('.student-group-join :contains("Leave")').click
        wait_for_ajaximations

        expect(f('div[role="list"]')).not_to include_text(@students[0].name.to_s)

        user_session(@teacher)
        get "/courses/#{@course.id}/groups"

        f(".group[data-id=\"#{@testgroup[0].id}\"] .toggle-group").click
        f(".group[data-id=\"#{@testgroup[1].id}\"] .toggle-group").click
        wait_for_ajaximations

        # Ensure First Student is no longer in groups, but in Unassigned Students section
        expect(f('div[data-view="groups"]')).not_to include_text(@students[0].name.to_s)
        expect(f(".unassigned-students")).to include_text(@students[0].name.to_s)
        # Fourth student should remain group leader
        expect(fj(".group[data-id=\"#{@testgroup[0].id}\"] .group-leader:contains(\"#{@students[3].name}\")")).to be_displayed
      end
    end

    describe "student group index page" do
      before do
        create_group(group_name:)
        get "/courses/#{@course.id}/groups"
      end

      it "leaving a group should decrement student count", priority: "1" do
        expect(f(".student-group-students")).to include_text("1 student")

        find_button("Leave").click

        expect(f(".student-group-students")).to include_text("0 students")
        expect(find_button("Join")).to be_displayed
      end

      it "student should be able to leave a group and rejoin", priority: "1" do
        # verify that you are in the group
        leave_button = find_button("Leave")
        expect(leave_button).to be_displayed

        # leave group and verify leaving
        leave_button.click
        join_button = find_button("Join")
        expect(join_button).to be_displayed

        # rejoin group
        join_button.click
        expect(find_button("Leave")).to be_displayed
      end

      it "visits the group", priority: "1" do
        fln("Visit").click
        wait_for_ajaximations

        expect(f("#breadcrumbs")).to include_text(group_name.to_s)
      end

      it "student group leader can manage group", priority: "2" do
        fln("Manage").click
        wait_for_ajaximations

        expect(f(".ui-dialog-titlebar")).to include_text("Manage Student Group")
      end
    end

    describe "student who is not in the group", priority: "2" do
      it "allows the student to join a student group they did not create" do
        create_group(group_name:, enroll_student_count: 0, add_self_to_group: false)
        get "/courses/#{@course.id}/groups"

        # join group
        find_button("Join").click
        expect(find_button("Leave")).to be_displayed
      end
    end

    describe "Manage Student Group Page" do
      before do
        create_group(group_name:, enroll_student_count: 2)
        get "/courses/#{@course.id}/groups"
      end

      it "populates dialog with current group name", priority: "2" do
        fln("Manage").click
        wait_for_ajaximations

        expect(f("#group_name")).to have_attribute(:value, group_name.to_s)
      end

      it "changes group name", priority: "2" do
        fln("Manage").click
        wait_for_ajaximations

        addition = "CRIT"
        f("#group_name").send_keys(addition.to_s)
        wait_for_ajaximations
        f("button.confirm-dialog-confirm-btn").click

        new_group_name = group_name.to_s + addition.to_s
        expect(f(".student-group-title")).to include_text(new_group_name.to_s)
      end

      it "adds users to group", priority: "1" do
        # expand the group
        fj(".student-group-title").click
        wait_for_ajaximations

        # verify that there is only one student
        # first item in the array is the group name
        students = ff("[role=listitem]")
        expect(students.length).to eq 2
        expect(students[1]).to include_text("nobody@example.com")

        fln("Manage").click
        wait_for_ajaximations

        students = ffj(".checkbox")
        students.each(&:click)

        fj("button.confirm-dialog-confirm-btn").click
        wait_for_ajaximations

        expected_student_list = ["nobody@example.com", "Test Student 1", "Test Student 2"]
        student_list = ff("[role=listitem]")

        # first item in the student_list array is the group name
        # I skip the group name and then do an index-1 to account for skipping index 0
        student_list.each_with_index do |student, index|
          if index != 0
            expect(student).to include_text(expected_student_list[index - 1].to_s)
          end
        end
      end
    end

    describe "student group search" do
      before do
        seed_students(2)
        seed_groups(1, 2)
        add_users_to_group(@students, @testgroup.first)
        get "/courses/#{@course.id}/groups"
      end

      it "works for searching by user's name" do
        wait_for_spinner { f('[data-testid="group-search-input"]').send_keys(@students.first.name) }
        wait_for_ajaximations
        expect(ff("div[role='listitem']").length).to eq 1
        f("[data-testid=\"open-group-dropdown-#{@testgroup.first.name}\"]").click
        expect(f("div[role='listitem']")).to include_text(@students.first.name)
      end

      it "works for searching by group's name" do
        wait_for_spinner { f('[data-testid="group-search-input"]').send_keys(@testgroup.last.name) }
        wait_for_ajaximations
        expect(ff("div[role='listitem']").length).to eq 1
        expect(f("div[role='listitem']")).to include_text(@testgroup.last.name)
      end
    end
  end
end

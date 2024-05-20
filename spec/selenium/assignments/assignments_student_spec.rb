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
require_relative "../helpers/assignments_common"
require_relative "../helpers/google_drive_common"

describe "assignments" do
  include_context "in-process server selenium tests"
  include GoogleDriveCommon
  include AssignmentsCommon

  context "as a student" do
    before do
      course_with_student_logged_in
    end

    before do
      @due_date = Time.now.utc + 2.days
      @assignment = @course.assignments.create!(title: "default assignment", name: "default assignment", due_at: @due_date)
    end

    it "orders undated assignments by title and dated assignments by first due" do
      @second_assignment = @course.assignments.create!(title: "assignment 2", name: "assignment 2", due_at: nil)
      @third_assignment = @course.assignments.create!(title: "assignment 3", name: "assignment 3", due_at: nil)
      @fourth_assignment = @course.assignments.create!(title: "assignment 4", name: "assignment 4", due_at: @due_date - 1.day)

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations
      titles = ff(".ig-title")
      expect(titles[0].text).to eq @fourth_assignment.title
      expect(titles[1].text).to eq @assignment.title
      expect(titles[2].text).to eq @second_assignment.title
      expect(titles[3].text).to eq @third_assignment.title
    end

    it "highlights mini-calendar dates where stuff is due" do
      @course.assignments.create!(title: "test assignment", name: "test assignment", due_at: @due_date)

      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
      expect(f(".mini_calendar_day.date_#{@due_date.strftime("%m_%d_%Y")}")).to have_class("has_event")
    end

    it "does not show submission data when muted" do
      assignment = @course.assignments.create!(title: "test assignment", name: "test assignment")

      assignment.update(submission_types: "online_url,online_upload", muted: false)
      submission = assignment.submit_homework(@student)
      submission.submission_type = "online_url"
      submission.save!

      submission.add_comment(author: @teacher, comment: "comment before muting")
      assignment.mute!
      assignment.update_submission(@student, hidden: true, comment: "comment after muting")

      outcome_with_rubric
      @rubric.associate_with(assignment, @course, purpose: "grading")

      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      details = f(".details")
      expect(details).not_to include_text("comment before muting")
      expect(details).not_to include_text("comment after muting")
    end

    it "has group comment radio buttons for individually graded group assignments" do
      u1 = @user
      student_in_course(course: @course)
      assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload,online_text_entry", group_category: GroupCategory.create!(name: "groups", context: @course), grade_group_students_individually: true)
      group = assignment.group_category.groups.create!(name: "g1", context: @course)
      group.users << u1
      group.users << @user

      get "/courses/#{@course.id}/assignments/#{assignment.id}"

      acceptable_tabs = ffj("#submit_online_upload_form,#submit_online_text_entry_form,#submit_online_url_form")
      expect(acceptable_tabs.size).to be 3
      acceptable_tabs.each do |tabby|
        expect(ffj('.formtable input[type="radio"][name="submission[group_comment]"]', tabby).size).to be 2
      end
    end

    it "has hidden group comment input for group graded group assignments" do
      u1 = @user
      student_in_course(course: @course)
      assignment = @course.assignments.create!(
        title: "some assignment",
        submission_types: "online_url,online_upload,online_text_entry",
        group_category: GroupCategory.create!(name: "groups", context: @course),
        grade_group_students_individually: false
      )
      group = assignment.group_category.groups.create!(name: "g1", context: @course)
      group.users << u1
      group.users << @user

      get "/courses/#{@course.id}/assignments/#{assignment.id}"

      acceptable_tabs = ffj("#submit_online_upload_form,#submit_online_text_entry_form,#submit_online_url_form")
      expect(acceptable_tabs.size).to be 3
      acceptable_tabs.each do |tabby|
        expect(ffj('.formtable input[type="hidden"][name="submission[group_comment]"]', tabby).size).to be 1
      end
    end

    it "does not show assignments in an unpublished course" do
      new_course = Course.create!(name: "unpublished course")
      assignment = new_course.assignments.create!(title: "some assignment")
      new_course.enroll_user(@user, "StudentEnrollment")
      get "/courses/#{new_course.id}/assignments/#{assignment.id}"

      expect(f("#unauthorized_message")).to be_displayed
      expect(f("#content")).not_to contain_css("#assignment_show")
    end

    it "verifies lock until date is enforced" do
      assignment_name = "locked assignment"
      unlock_time = 1.day.from_now
      locked_assignment = @course.assignments.create!(name: assignment_name, unlock_at: unlock_time)

      get "/courses/#{@course.id}/assignments/#{locked_assignment.id}"
      expect(f("#content")).to include_text(format_date_for_view(unlock_time))
      locked_assignment.update(unlock_at: Time.now)
      refresh_page # to show the updated assignment
      expect(f("#content")).not_to include_text("This assignment is locked until")
    end

    it "verifies due date is enforced" do
      due_date_assignment = @course.assignments.create!(name: "due date assignment", due_at: 5.days.ago)
      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations
      expect(f("#assignment_group_past #assignment_#{due_date_assignment.id}")).to be_displayed
      due_date_assignment.update(due_at: 2.days.from_now)
      refresh_page # to show the updated assignment
      expect(f("#assignment_group_upcoming #assignment_#{due_date_assignment.id}")).to be_displayed
    end

    it "shows assignment data if locked by due date or lock date" do
      assignment = @course.assignments.create!(name: "locked assignment",
                                               due_at: 5.days.ago,
                                               lock_at: 3.days.ago)
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css(".submit_assignment_link")
      expect(f(".student-assignment-overview")).to be_displayed
    end

    it "does not show assignment data if locked by unlock date" do
      assignment = @course.assignments.create!(name: "not unlocked assignment",
                                               due_at: 5.days.from_now,
                                               unlock_at: 3.days.from_now)
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css(".student-assignment-overview")
    end

    context "overridden lock_at" do
      before do
        setup_sections_and_overrides_all_future
        @course.enroll_user(@student, "StudentEnrollment", section: @section2, enrollment_state: "active")
      end

      it "shows overridden lock dates for student" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, " ")
        expect(f("#content")).to include_text "locked until #{expected_unlock}."
      end

      it "allows submission when within override locks" do
        @assignment.update(submission_types: "online_text_entry")
        # Change unlock dates to be valid for submission
        @override.unlock_at = Time.now.utc - 1.day # available now
        @override.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f(".submit_assignment_link").click
        wait_for_ajaximations
        assignment_form = f("#submit_online_text_entry_form")
        wait_for_tiny(assignment_form)
        wait_for_ajaximations
        body_text = "something to submit"
        expect do
          type_in_tiny("#submission_body", body_text)
          wait_for_ajaximations
          submit_form(assignment_form)
          wait_for_ajaximations
        end.to change {
          @assignment.submissions.find_by!(user: @student).body
        }.from(nil).to("<p>#{body_text}</p>")
      end
    end

    context "click_away_accept_alert" do # this context exits to handle the click_away_accept_alert method call after each spec that needs it even if it fails early to prevent other specs from failing
      after do
        click_away_accept_alert
      end

      it "expands the comments box on click" do
        @assignment.update(submission_types: "online_upload")

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(".submit_assignment_link").click
        wait_for_ajaximations
        expect(driver.execute_script("return $('#submission_comment').height()")).to eq 20
        driver.execute_script("$('#submission_comment').focus()")
        wait_for_ajaximations
        expect(driver.execute_script("return $('#submission_comment').height()")).to eq 72
      end

      it "validates file upload restrictions" do
        _filename_txt, fullpath_txt, _data_txt, _tempfile_txt = get_file("testfile4.txt")
        _filename_zip, fullpath_zip, _data_zip, _tempfile_zip = get_file("testfile5.zip")
        @assignment.update(submission_types: "online_upload", allowed_extensions: ".txt")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f(".submit_assignment_link").click

        submit_file_button = f("#submit_file_button")
        submission_input = f(".submission_attachment input")
        ext_error = f(".bad_ext_msg")

        submission_input.send_keys(fullpath_txt)
        expect(ext_error).not_to be_displayed
        expect(submit_file_button["disabled"]).to be_nil
        submission_input.send_keys(fullpath_zip)
        expect(ext_error).to be_displayed
        expect(submit_file_button).to be_disabled
      end
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "lists the assignments" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations
      move_to_click("label[for=show_by_type]")
      ag_el = f("#assignment_group_#{ag.id}")
      expect(ag_el).to be_present
      expect(ag_el.text).to match @assignment.name
    end

    it "lists the assignments with the instui_nav flag on" do
      @course.root_account.enable_feature!(:instui_nav)
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations
      f('[data-view="showBy"] [type="button"]').click
      f('[data-testid="show_by_type"]').click
      ag_el = f("#assignment_group_#{ag.id}")
      expect(ag_el).to be_present
      expect(ag_el.text).to match @assignment.name
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "does not show add/edit/delete buttons" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css(".new_assignment")
      expect(f("#content")).not_to contain_css("#addGroup")
      expect(f("#content")).not_to contain_css(".add_assignment")
      move_to_click("label[for=show_by_type]")
      expect(f("#content")).not_to contain_css("ag_#{ag.id}_manage_link")
    end

    it "does not show add/edit/delete buttons with the instui nav flag on" do
      @course.root_account.enable_feature!(:instui_nav)
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css("[data-testid='new_assignment_button']")
      expect(f("#content")).not_to contain_css("[data-testid='new_group_button']")
      expect(f("#content")).not_to contain_css(".add_assignment")
      f('[data-view="showBy"] [type="button"]').click
      f('[data-testid="show_by_type"]').click
      expect(f("#content")).not_to contain_css("ag_#{ag.id}_manage_link")
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "defaults to grouping by date" do
      @course.assignments.create!(title: "undated assignment", name: "undated assignment")

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      expect(is_checked("#show_by_date")).to be_truthy

      # assuming two undated and two future assignments created above
      expect(f("#assignment_group_upcoming")).not_to be_nil
      expect(f("#assignment_group_undated")).not_to be_nil
    end

    it "defaults to grouping by date with instui nav flag on" do
      @course.root_account.enable_feature!(:instui_nav)
      @course.assignments.create!(title: "undated assignment", name: "undated assignment")

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      f('[data-view="showBy"] [type="button"]').click
      expect(f('[data-testid="show_by_date"]').attribute("aria-checked")).to eq "true"

      # assuming two undated and two future assignments created above
      expect(f("#assignment_group_upcoming")).not_to be_nil
      expect(f("#assignment_group_undated")).not_to be_nil
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "allowings grouping by assignment group (and remember)" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      move_to_click("label[for=show_by_type]")
      expect(is_checked("#show_by_type")).to be_truthy
      expect(f("#assignment_group_#{ag.id}")).not_to be_nil

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations
      expect(is_checked("#show_by_type")).to be_truthy
    end

    it "allowings grouping by assignment group (and remember) with the instui nav flag on" do
      @course.root_account.enable_feature!(:instui_nav)
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      f('[data-view="showBy"] [type="button"]').click
      f('[data-testid="show_by_type"]').click
      f('[data-view="showBy"] [type="button"]').click
      expect(f('[data-testid="show_by_type"]').attribute("aria-checked")).to eq "true"
      expect(f("#assignment_group_#{ag.id}")).not_to be_nil

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations
      f('[data-view="showBy"] [type="button"]').click
      expect(f('[data-testid="show_by_type"]').attribute("aria-checked")).to eq "true"
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "does not show empty groups" do
      # assuming two undated and two future assignments created above
      empty_ag = @course.assignment_groups.create!(name: "Empty")

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css("#assignment_group_overdue")
      expect(f("#content")).not_to contain_css("#assignment_group_past")

      move_to_click("label[for=show_by_type]")
      expect(f("#content")).not_to contain_css("#assignment_group_#{empty_ag.id}")
    end

    it "does not show empty groups with instui nav flag on" do
      @course.root_account.enable_feature!(:instui_nav)
      # assuming two undated and two future assignments created above
      empty_ag = @course.assignment_groups.create!(name: "Empty")

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css("#assignment_group_overdue")
      expect(f("#content")).not_to contain_css("#assignment_group_past")

      f('[data-view="showBy"] [type="button"]').click
      f('[data-testid="show_by_type"]').click
      expect(f("#content")).not_to contain_css("#assignment_group_#{empty_ag.id}")
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "shows empty assignment groups if they have a weight" do
      @course.group_weighting_scheme = "percent"
      @course.save!

      ag = @course.assignment_groups.first
      ag.group_weight = 90
      ag.save!

      empty_ag = @course.assignment_groups.create!(name: "Empty", group_weight: 10)

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      move_to_click("label[for=show_by_type]")
      expect(f("#assignment_group_#{empty_ag.id}")).not_to be_nil
    end

    it "shows empty assignment groups if they have a weight with the instui nav flag on" do
      @course.root_account.enable_feature!(:instui_nav)
      @course.group_weighting_scheme = "percent"
      @course.save!

      ag = @course.assignment_groups.first
      ag.group_weight = 90
      ag.save!

      empty_ag = @course.assignment_groups.create!(name: "Empty", group_weight: 10)

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      f('[data-view="showBy"] [type="button"]').click
      f('[data-testid="show_by_type"]').click
      expect(f("#assignment_group_#{empty_ag.id}")).not_to be_nil
    end

    it "categorizes assignments by date correctly" do
      # assuming two undated and two future assignments created above
      undated, upcoming = @course.assignments.partition { |a| a.due_date.nil? }

      get "/courses/#{@course.id}/assignments"
      wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
      wait_for_ajaximations

      undated.each do |a|
        expect(f("#assignment_group_undated #assignment_#{a.id}")).not_to be_nil
      end

      upcoming.each do |a|
        expect(f("#assignment_group_upcoming #assignment_#{a.id}")).not_to be_nil
      end
    end

    context "proxy submitted assignment" do
      before do
        @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
        @assignment.update!(submission_types: "online_upload,online_text_entry")
        Account.site_admin.enable_feature!(:proxy_file_uploads)
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
        RoleOverride.create!(
          permission: "proxy_assignment_submission",
          enabled: true,
          role: teacher_role,
          account: @course.root_account
        )
        file_attachment = attachment_model(content_type: "application/pdf", context: @student)
        submission = @assignment.submit_homework(@student, submission_type: "online_upload", attachments: [file_attachment])
        @teacher.update!(short_name: "Test Teacher")
        submission.update!(proxy_submitter: @teacher)
        user_session(@student)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      end

      it "identifies the proxy submitter in the submission details" do
        expect(f(".details").text).to include("by " + @teacher.short_name)
      end
    end

    context "with more than one page of assignment groups" do
      before do
        ApplicationController::ASSIGNMENT_GROUPS_TO_FETCH_PER_PAGE_ON_ASSIGNMENTS_INDEX = 10
        @count_to_make = ApplicationController::ASSIGNMENT_GROUPS_TO_FETCH_PER_PAGE_ON_ASSIGNMENTS_INDEX + 2

        # we suspend these callbacks here to speed up the spec
        AssignmentGroup.suspend_callbacks(kind: :save) do
          Assignment.suspend_callbacks(kind: :save) do
            @count_to_make.times do |i|
              ag = @course.assignment_groups.create!(name: "AG #{i}")
              ag.assignments.create!(context: @course, name: "assignment #{i}", submission_types: "online_text_entry")
            end
          end
        end
        # by enrolling a new user it will do all the SubmissionLifecycleManager stuff we skipped above
        course_with_student_logged_in(course: @course)
      end

      # EVAL-3711 Remove this test when instui_nav feature flag is removed
      it "exhausts all pagination of assignment groups" do
        get "/courses/#{@course.id}/assignments"
        wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
        wait_for_ajaximations
        # if there are more assignment_groups visible than we fetch per page,
        # it must mean that it paginated succcessfully

        count_to_expect = @count_to_make + 1 # add one for the @assignment created in the root `before` block
        expect(ff('[data-view="assignmentGroups"] .assignment').length).to eq(count_to_expect)

        move_to_click("label[for=show_by_type]")
        expect(ff('[data-view="assignmentGroups"] .assignment_group').length).to eq(count_to_expect)
      end

      it "exhausts all pagination of assignment groups with the instui nav flag on" do
        @course.root_account.enable_feature!(:instui_nav)
        get "/courses/#{@course.id}/assignments"
        wait_for_no_such_element { f('[data-view="assignmentGroups"] .loadingIndicator') }
        wait_for_ajaximations
        # if there are more assignment_groups visible than we fetch per page,
        # it must mean that it paginated succcessfully

        count_to_expect = @count_to_make + 1 # add one for the @assignment created in the root `before` block
        expect(ff('[data-view="assignmentGroups"] .assignment').length).to eq(count_to_expect)

        f('[data-view="showBy"] [type="button"]').click
        f('[data-testid="show_by_type"]').click
        expect(ff('[data-view="assignmentGroups"] .assignment_group').length).to eq(count_to_expect)
      end
    end
  end
end

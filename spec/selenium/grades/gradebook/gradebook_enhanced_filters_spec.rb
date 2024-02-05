# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_grade_detail_tray_page"
require_relative "../../helpers/gradebook_common"
require_relative "../setup/gradebook_setup"

describe "Enhanced Gradebook Filters" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup
  include_context "late_policy_course_setup"

  def format_grading_period_title_with_date(grp)
    dates = [grp.start_date, grp.end_date, grp.close_date].map { |d| format_date_for_view(d, "%-m/%-d/%y") }
    "#{grp.title}: #{dates[0]} - #{dates[1]} | #{dates[2]}"
  end

  before(:once) do
    Account.site_admin.enable_feature!(:enhanced_gradebook_filters)
    Account.site_admin.enable_feature!(:custom_gradebook_statuses)
    init_course_with_students(2)
    create_course_late_policy
    create_assignments
    make_submissions
    grade_assignments
    @now = Time.zone.now
    create_grading_periods("Fall Term", @now)
    associate_course_to_term("Fall Term")
    @student1 = @students[0]
    @student2 = @students[1]
    @a5 = @course.assignments.create!(
      title: "assignment five",
      grading_type: "points",
      points_possible: 10,
      due_at: 7.days.from_now(@now),
      submission_types: "online_text_entry"
    )
    @a6 = @course.assignments.create!(
      title: "assignment six",
      grading_type: "points",
      points_possible: 10,
      due_at: 7.days.from_now(@now),
      submission_types: "online_text_entry"
    )
    @section1 = @course.course_sections.create!(name: "Section1")
    @section2 = @course.course_sections.create!(name: "Section2")
    student_in_section(@section1, user: @student1)
    student_in_section(@section2, user: @student2)
    @assignment_group1 = @course.assignment_groups.create!(name: "AssignmentGroup1")
    @assignment_group2 = @course.assignment_groups.create!(name: "AssignmentGroup2")
    @assignment_group2.update!(rules: "drop_lowest:1")
    @a1.update!(due_at: 15.days.ago(@now), assignment_group: @assignment_group1)
    @a2.update!(due_at: 10.days.from_now(@now), assignment_group: @assignment_group2)
    @a3.update!(assignment_group: @assignment_group2)
    @a2.submit_homework(@student2, body: "submission", submitted_at: 1.day.ago(@now))
    @a4.submit_homework(@student2, body: "submission", submitted_at: 1.day.ago(@now))
    @a5.ensure_post_policy(post_manually: true)
    @module1 = @course.context_modules.create!(name: "module1")
    @module2 = @course.context_modules.create!(name: "module2")
    @module1.add_item(id: @a1.id, type: "assignment")
    @module2.add_item(id: @a2.id, type: "assignment")
    @group1 = @course.groups.create!(name: "group1")
    @group2 = @course.groups.create!(name: "group2")
    @group1.add_user(@student1)
    @group1.save!
    @group2.add_user(@student2)
    @group2.save!
    @custom_status = CustomGradeStatus.create!(name: "No Presentado", color: "#00ffff", created_by: @teacher, root_account_id: @course.root_account_id)
    Submission.find_by(assignment_id: @a2.id, user_id: @student1).update!(late_policy_status: "missing")
    Submission.find_by(assignment_id: @a2.id, user_id: @student2).update!(late_policy_status: "late")
    Submission.find_by(assignment_id: @a3.id, user_id: @student1).update!(late_policy_status: "extended")
    Submission.find_by(assignment_id: @a3.id, user_id: @student2).update!(grade_matches_current_submission: false, workflow_state: "submitted")
    Submission.find_by(assignment_id: @a6.id, user_id: @student1).update!(custom_grade_status_id: @custom_status.id)
    @a2.grade_student(@student2, grade: 10, grader: @teacher)
    @a5.grade_student(@student2, grade: 10, grader: @teacher)
  end

  describe "feature flag OFF" do
    before do
      Account.site_admin.disable_feature!(:enhanced_gradebook_filters)
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "Enhanced filters button is not visible", priority: "1" do
      expect(f("body")).not_to contain_jqcss('button:contains("Filters")')
    end
  end

  describe "feature flag ON" do
    before do
      Account.site_admin.enable_feature!(:enhanced_gradebook_filters)
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "Enhanced filters button is visible", priority: "1" do
      expect(fj('button:contains("Filters")')).to be_displayed
    end

    describe "adhoc filters" do
      it "can filter and unfilter by student" do
        Gradebook.students_filter_select.send_keys(@student1.name)
        Gradebook.students_filter_select.click
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.remove_student_or_assignment_filter(@student1.name)
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by assignment" do
        Gradebook.assignments_filter_select.send_keys(@a2.name)
        Gradebook.assignments_filter_select.click
        expect(Gradebook.fetch_assignment_names).to eq [@a2.name]

        Gradebook.remove_student_or_assignment_filter(@a2.name)
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
      end

      it "can filter and unfilter by module" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Modules")
        Gradebook.select_filter_menu_item(@module2.name)
        expect(Gradebook.fetch_assignment_names).to eq [@a2.name]

        Gradebook.select_filter_menu_item(@module2.name)
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
      end

      it "can filter and unfilter by section" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Sections")
        Gradebook.select_filter_menu_item(@section1.name)
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_filter_menu_item(@section1.name)
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "does not update default grades for users not in this section" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Sections")
        Gradebook.select_filter_menu_item(@section1.name)
        expect(Gradebook.fetch_student_names).to eq [@student1.name]
        Gradebook.click_assignment_header_menu(@a6.id)
        set_default_grade(13)
        @section1.users.each { |u| expect(u.submissions.map(&:grade)).to include "13" }
        @section2.users.each { |u| expect(u.submissions.map(&:grade)).not_to include "13" }
      end

      it "can filter and unfilter by student group" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Student Groups")
        Gradebook.select_sorted_filter_menu_item(@group1.name)
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_sorted_filter_menu_item(@group1.name)
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by grading period" do
        title = format_grading_period_title_with_date(@gp_closed)
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Grading Periods")
        Gradebook.select_filter_menu_item(title)
        expect(Gradebook.fetch_assignment_names).to eq [@a1.name]

        Gradebook.select_filter_menu_item(title)
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
      end

      it "can filter and unfilter by assignment group" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Assignment Groups")
        Gradebook.select_filter_menu_item(@assignment_group2.name)
        expect(Gradebook.fetch_assignment_names).to eq [@a2.name, @a3.name]

        Gradebook.select_filter_menu_item(@assignment_group2.name)
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
      end

      it "can filter and unfilter by excused status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Excused")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_filter_menu_item("Excused")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by late status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Late")
        expect(Gradebook.fetch_assignment_names).to eq [@a2.name]
        expect(Gradebook.fetch_student_names).to eq [@student2.name]

        Gradebook.select_filter_menu_item("Late")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by missing status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Missing")
        expect(Gradebook.fetch_assignment_names).to eq [@a2.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_filter_menu_item("Missing")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by resubmitted status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Resubmitted")
        expect(Gradebook.fetch_assignment_names).to eq [@a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student2.name]

        Gradebook.select_filter_menu_item("Resubmitted")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by dropped status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Dropped")
        expect(Gradebook.fetch_assignment_names).to eq [@a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_filter_menu_item("Dropped")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by extended status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Extended")
        expect(Gradebook.fetch_assignment_names).to eq [@a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_filter_menu_item("Extended")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by custom status" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("No Presentado")
        expect(Gradebook.fetch_assignment_names).to eq [@a6.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.select_filter_menu_item("No Presentado")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by ungraded submissions" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Submissions")
        Gradebook.select_filter_menu_item("Has Ungraded Submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name]
        expect(Gradebook.fetch_student_names).to eq [@student2.name]

        Gradebook.select_filter_menu_item("Has Ungraded Submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by submitted submissions" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Submissions")
        Gradebook.select_filter_menu_item("Has Submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]

        Gradebook.select_filter_menu_item("Has Submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by unsubmitted submissions" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Submissions")
        Gradebook.select_filter_menu_item("Has No Submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a5.name, @a6.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]

        Gradebook.select_filter_menu_item("Has No Submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter by unposted grades" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Submissions")
        Gradebook.select_filter_menu_item("Has Unposted Grades")
        expect(Gradebook.fetch_assignment_names).to eq [@a5.name]
        expect(Gradebook.fetch_student_names).to eq [@student2.name]

        Gradebook.select_filter_menu_item("Has Unposted Grades")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter and unfilter by date range of assignment due dates" do
        skip "FOO-3793 (10/6/2023)"
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Start & End Date")
        Gradebook.input_start_date(6.days.from_now(@now))
        Gradebook.input_end_date(8.days.from_now(@now))
        # not working in the test but works manually in the browser
        Gradebook.apply_date_filter
        expect(Gradebook.fetch_assignment_names).to eq [@a5.name, @a6.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]

        Gradebook.select_filter_type_menu_item("Start & End Date")
        Gradebook.clear_start_date_input
        Gradebook.clear_end_date_input
        # not working in the test but works manually in the browser
        Gradebook.apply_date_filter
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter by date range of assignment due dates with just a start date" do
        skip "FOO-3793 (10/6/2023)"
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Start & End Date")
        Gradebook.input_start_date(9.days.from_now(@now))
        # not working in the test but works manually in the browser
        Gradebook.apply_date_filter

        expect(Gradebook.fetch_assignment_names).to eq [@a2.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter by date range of assignment due dates with just an end date" do
        skip "FOO-3793 (10/6/2023)"
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Start & End Date")
        Gradebook.input_end_date(3.days.from_now(@now))
        # not working in the test but works manually in the browser
        Gradebook.apply_date_filter

        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "status and submissions filter types will replace each other when enabled (cannot filter at the same time)" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Submissions")
        Gradebook.select_filter_menu_item("Has Unposted Grades")
        expect(Gradebook.fetch_assignment_names).to eq [@a5.name]
        expect(Gradebook.fetch_student_names).to eq [@student2.name]

        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Resubmitted")
        expect(Gradebook.fetch_assignment_names).to eq [@a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student2.name]
      end

      it "can filter by multiple types(modules, student groups, submissions, grading periods) of filters each are shown above the gradebook in a pill where they can be deseleted" do
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Modules")
        Gradebook.select_filter_menu_item("module1")
        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Submissions")
        Gradebook.select_filter_menu_item("Has Submissions")
        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Student Groups")
        Gradebook.select_sorted_filter_menu_item("group1")
        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Grading Periods")
        gp_title = format_grading_period_title_with_date(@gp_closed)
        Gradebook.select_filter_menu_item(gp_title)
        expect(Gradebook.fetch_assignment_names).to eq [@a1.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.clear_filter(gp_title)
        Gradebook.clear_filter("module1")
        expect(Gradebook.fetch_assignment_names).to eq [@a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.clear_filter("Has submissions")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]

        Gradebook.clear_filter("group1")
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end

      it "can filter by multiple types(sections, assignment groups, status, dates) of filters each are shown above the gradebook in a pill where they can be deseleted" do
        skip "FOO-3793 (10/6/2023)"
        Gradebook.apply_filters_button.click
        Gradebook.select_filter_type_menu_item("Sections")
        Gradebook.select_filter_menu_item("Section1")
        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Assignment Groups")
        Gradebook.select_filter_menu_item("AssignmentGroup2")
        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Status")
        Gradebook.select_filter_menu_item("Dropped")
        Gradebook.select_filter_dropdown_back_button
        Gradebook.select_filter_type_menu_item("Start & End Date")
        Gradebook.input_start_date(1.day.from_now(@now))
        Gradebook.input_end_date(3.days.from_now(@now))
        Gradebook.apply_date_filter
        expect(Gradebook.fetch_assignment_names).to eq [@a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.clear_filter("Dropped")
        Gradebook.clear_filter("AssignmentGroup2")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]

        Gradebook.clear_filter("Section1")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]

        Gradebook.clear_filter("Start Date #{format_date_for_view(1.day.from_now(@now), "%-m/%-d/%Y")}")
        Gradebook.clear_filter("End Date #{format_date_for_view(3.days.from_now(@now), "%-m/%-d/%Y")}")
        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
      end
    end

    describe "filter presets" do
      it "can create a filter preset with all filter types" do
        Gradebook.apply_filters_button.click
        Gradebook.manage_filter_presets_button.click
        Gradebook.create_filter_preset_dropdown.click
        Gradebook.input_preset_filter_name("preset1")
        Gradebook.select_filter_preset_dropdown_option("Sections", @section1.name)
        Gradebook.select_filter_preset_dropdown_option("Assignment Groups", @assignment_group2.name)
        Gradebook.select_filter_preset_dropdown_option("Submissions", "Dropped")
        Gradebook.select_filter_preset_dropdown_option("Modules", @module1.name)
        Gradebook.select_filter_preset_dropdown_option("Student Groups", @group1.name)
        Gradebook.select_filter_preset_dropdown_option("Grading Periods", @gp_closed.title)
        Gradebook.start_date_input.click
        Gradebook.input_start_date(1.day.from_now(@now))
        Gradebook.start_date_input.send_keys(:enter)
        Gradebook.end_date_input.click
        Gradebook.input_end_date(3.days.from_now(@now))
        Gradebook.end_date_input.send_keys(:enter)
        Gradebook.save_filter_preset

        expect(Gradebook.filter_preset_dropdown("preset1")).to be_displayed
      end

      it "can delete a filter preset from the tray" do
        Gradebook.apply_filters_button.click
        Gradebook.manage_filter_presets_button.click
        Gradebook.create_filter_preset_dropdown.click
        Gradebook.input_preset_filter_name("preset1")
        Gradebook.select_filter_preset_dropdown_option("Sections", @section1.name)
        Gradebook.save_filter_preset
        Gradebook.filter_preset_dropdown("preset1").click

        expect(Gradebook.delete_filter_preset_button).to be_displayed
      end

      it "can edit a filter preset from the tray" do
        Gradebook.apply_filters_button.click
        Gradebook.manage_filter_presets_button.click
        Gradebook.create_filter_preset_dropdown.click
        Gradebook.input_preset_filter_name("preset1")
        Gradebook.select_filter_preset_dropdown_option("Sections", @section1.name)
        Gradebook.save_filter_preset
        Gradebook.filter_preset_dropdown("preset1").click
        Gradebook.select_filter_preset_dropdown_option("Modules", @module1.name)

        expect(Gradebook.filter_preset_dropdown_type("Modules").attribute("value")).to eq @module1.name
      end

      it "can enable and all of the appropriate filter pills will be displayed" do
        Gradebook.apply_filters_button.click
        Gradebook.manage_filter_presets_button.click
        Gradebook.create_filter_preset_dropdown.click
        Gradebook.input_preset_filter_name("preset1")
        Gradebook.select_filter_preset_dropdown_option("Sections", @section1.name)
        Gradebook.select_filter_preset_dropdown_option("Assignment Groups", @assignment_group2.name)
        Gradebook.select_filter_preset_dropdown_option("Submissions", "Dropped")
        Gradebook.select_filter_preset_dropdown_option("Modules", @module1.name)
        Gradebook.save_filter_preset
        Gradebook.apply_filters_button.click
        Gradebook.enable_filter_preset("preset1")

        expect(Gradebook.filter_pill(@section1.name)).to be_displayed
        expect(Gradebook.filter_pill(@assignment_group2.name)).to be_displayed
        expect(Gradebook.filter_pill("Dropped")).to be_displayed
        expect(Gradebook.filter_pill(@module1.name)).to be_displayed
      end

      it "can enable a filter preset to filter the gradebook by multiple filter types" do
        Gradebook.apply_filters_button.click
        Gradebook.manage_filter_presets_button.click
        Gradebook.create_filter_preset_dropdown.click
        Gradebook.input_preset_filter_name("preset1")
        Gradebook.select_filter_preset_dropdown_option("Sections", @section1.name)
        Gradebook.select_filter_preset_dropdown_option("Modules", @module2.name)
        Gradebook.save_filter_preset

        Gradebook.apply_filters_button.click
        Gradebook.enable_filter_preset("preset1")

        expect(Gradebook.fetch_assignment_names).to eq [@a2.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name]
      end

      it "can clear all filter presets with the clear all filters button" do
        Gradebook.apply_filters_button.click
        Gradebook.manage_filter_presets_button.click
        Gradebook.create_filter_preset_dropdown.click
        Gradebook.input_preset_filter_name("preset1")
        Gradebook.select_filter_preset_dropdown_option("Sections", @section1.name)
        Gradebook.select_filter_preset_dropdown_option("Modules", @module2.name)
        Gradebook.save_filter_preset

        Gradebook.apply_filters_button.click
        Gradebook.enable_filter_preset("preset1")
        Gradebook.clear_all_filters

        expect(Gradebook.fetch_assignment_names).to eq [@a4.name, @a5.name, @a6.name, @a2.name, @a3.name]
        expect(Gradebook.fetch_student_names).to eq [@student1.name, @student2.name]
      end
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe CoursesHelper do
  include ApplicationHelper
  include AssignmentsHelper
  include CoursesHelper
  include QuizzesHelper

  context "a view with a 'Coming Up' sidebar" do
    before(:once) do
      course_with_teacher(active_all: true)
      @assignment = @course.assignments.create!(
        assignment_valid_attributes.merge({ points_possible: 10,
                                            submission_types: "online_text_entry" })
      )
      @assignment2 = @course.assignments.create!(
        assignment_valid_attributes.merge({ points_possible: 10,
                                            submission_types: "none" })
      )
    end

    before do
      user_session(@user)
    end

    describe "an assignment with no submissions" do
      before(:once) do
        @student_one = User.create!(valid_user_attributes)
        @student_two = User.create!(valid_user_attributes)
        [@student_one, @student_two].each do |student|
          e = @course.enroll_student(student)
          e.invite
          e.accept
        end
        @assignment.reload
      end

      it "returns a no submission tooltip if there are no submissions" do
        expect(self).to receive(:t).with("#courses.recent_event.no_submissions", "no submissions").and_return("no submissions")
        check_icon_data("no submissions", "Assignment", "icon-assignment")
      end

      it "returns a not submitted tooltip for a student if they have not made a submission" do
        expect(self).to receive(:t).with("#courses.recent_event.not_submitted", "not submitted").and_return("not submitted")
        check_icon_data("not submitted", "Assignment", "icon-assignment", current_user: @student_one)
      end

      it "returns a nil tooltip for a student if the assignment does not expect a submission" do
        expect(self).to receive(:t).with("#courses.recent_event.not_submitted", "not submitted").and_return("not submitted")
        check_icon_data(nil, "Assignment", "icon-assignment", current_user: @student_one, recent_event: @assignment2)
      end
    end

    describe "an assignment with submissions" do
      before(:once) do
        @student_one = User.create!(valid_user_attributes)
        @student_two = User.create!(valid_user_attributes)
        [@student_one, @student_two].each do |student|
          e = @course.enroll_student(student)
          e.invite
          e.accept
        end
        @assignment.reload
      end

      it "returns a needs grading tooltip if assignments have been submitted that aren't graded" do
        expect(self).to receive(:t).with("#courses.recent_event.needs_grading", "needs grading").and_return("needs grading")
        @assignment.submit_homework(@student_one, { submission_type: "online_text_entry", body: "..." })
        check_icon_data("needs grading", "Assignment", "icon-assignment")
      end

      it "returns the submission's readable_state as the tooltip for a student" do
        submission = @assignment.submit_homework(@student_one, { submission_type: "online_text_entry", body: "..." })
        check_icon_data(submission.readable_state, "", "icon-check", current_user: @student_one, submission:)
      end

      it "returns an assignment icon instead of a check icon if show_assignment_type_icon is set" do
        submission = @assignment.submit_homework(@student_two, { submission_type: "online_text_entry", body: "..." })
        check_icon_data(submission.readable_state,
                        "Assignment",
                        "icon-assignment",
                        current_user: @student_two,
                        submission:,
                        show_assignment_type_icon: true)
      end

      it "returns a no new submissions tooltip if some assignments have been submitted and graded" do
        expect(self).to receive(:t).with("#courses.recent_event.no_new_submissions", "no new submissions").and_return("no new submissions")
        @assignment.submit_homework(@student_one, { submission_type: "online_text_entry", body: "xyz" })
        @assignment.grade_student(@student_one, grade: 5, grader: @teacher)
        check_icon_data("no new submissions", "Assignment", "icon-assignment")
      end

      it "returns an all graded tooltip if all assignments are submitted and graded" do
        expect(self).to receive(:t).with("#courses.recent_event.all_graded", "all graded").and_return("all graded")
        [@student_one, @student_two].each do |student|
          @assignment.submit_homework(student, { submission_type: "online_text_entry", body: "bod" })
          @assignment.grade_student(student, grade: 5, grader: @teacher)
        end
        check_icon_data("all graded", "Assignment", "icon-assignment")
      end
    end

    def check_icon_data(msg, aria_label, icon, options = {})
      base_options = {
        context: @course,
        contexts: [@course],
        current_user: @teacher,
        recent_event: @assignment,
        submission: nil
      }.merge(options)
      @icon_explanation, @icon_aria_label, @icon_class = icon_data(base_options)
      expect(@icon_explanation).to eql msg
      expect(@icon_aria_label).to eql aria_label
      expect(@icon_class).to eql icon
    end
  end

  context "readable_grade" do
    it "returns nil if not graded" do
      submission = Submission.new
      expect(readable_grade(submission)).to be_nil
    end

    it "returns the score if graded" do
      assignment = Assignment.new(points_possible: 5, grading_type: "points")
      submission = Submission.new(grade: 1.33333333, workflow_state: "graded", assignment:)
      expect(readable_grade(submission)).to eq "1.33 out of 5"
    end

    it "does not raise an error when passing a numeric type but grading_type is not 'points'" do
      assignment = Assignment.new(points_possible: 5, grading_type: "percent")
      submission = Submission.new(grade: 1.33333333, workflow_state: "graded", assignment:)
      expect(readable_grade(submission)).to eq "1.33333%"
    end
  end

  describe "#user_type" do
    let(:admin) { account_admin_user(account: Account.default, active_user: true) }
    let(:course) { Account.default.courses.create! }
    let(:teacher) { teacher_in_course(course:, active_all: true).user }
    let(:ta) { ta_in_course(course:, active_all: true).user }
    let(:student) { student_in_course(course:, active_all: true).user }
    let(:test_student) { course.student_view_student }
    let(:rando) { User.create! }
    let(:observer) do
      observer_user = User.create!
      enrollment = course.enroll_user(observer_user, "ObserverEnrollment")
      enrollment.update!(workflow_state: "active", associated_user: student)
      observer_user
    end

    it "returns nil for random users with no course association" do
      expect(user_type(course, rando)).to be_nil
    end

    it "returns 'teacher' for TeacherEnrollments" do
      expect(user_type(course, teacher)).to eq "teacher"
    end

    it "returns 'ta' for TaEnrollments" do
      expect(user_type(course, ta)).to eq "ta"
    end

    it "returns 'student' for StudentEnrollments" do
      expect(user_type(course, student)).to eq "student"
    end

    it "returns 'student' for StudentViewEnrollments" do
      expect(user_type(course, test_student)).to eq "student"
    end

    it "returns 'student' for ObserverEnrollments" do
      expect(user_type(course, observer)).to eq "student"
    end

    it "returns 'admin' for admin enrollments" do
      expect(user_type(course, admin)).to eq "admin"
    end

    it "can optionally be passed preloaded enrollments" do
      enrollments = course.enrollments.index_by(&:user_id)
      expect(course).not_to receive(:enrollments)
      user_type(course, teacher, enrollments)
    end

    it "returns the correct user type when passed preloaded enrollments" do
      enrollments = teacher && course.enrollments.index_by(&:user_id)
      expect(user_type(course, teacher, enrollments)).to eq "teacher"
    end
  end

  describe "#sortable_tabs" do
    it "returns tool tabs" do
      tool = external_tool_model(context: course_model)
      tool.course_navigation = { enabled: true }
      tool.save
      controller = CoursesController.new
      controller.instance_variable_set(:@context, tool.context)
      tabs = controller.sortable_tabs

      tool_tab = tabs.find { |t| Lti::ExternalToolTab.tool_for_tab(t) == tool }
      expect(tool_tab[:args][1]).to eq(tool.id)
    end

    context "when given a quizzes tool tab" do
      before do
        allow_any_instance_of(ContextExternalTool).to receive(:quiz_lti?).and_return(true)
      end

      context "quizzes is enabled for the course" do
        it "includes the tab" do
          tool = external_tool_model(context: course_model)
          tool.course_navigation = { enabled: true }
          tool.save
          controller = CoursesController.new
          controller.instance_variable_set(:@context, tool.context)

          Account.site_admin.enable_feature! :assignments_2_teacher
          allow(controller).to receive(:new_quizzes_navigation_placements_enabled?).with(tool.context).and_return(true)

          tabs = controller.sortable_tabs
          tool_tab = tabs.find { |t| Lti::ExternalToolTab.tool_for_tab(t) == tool }
          expect(tool_tab[:args][1]).to eq(tool.id)
        end
      end

      context "quizzes is disabled for the account/course" do
        it "doesn't include the tab" do
          tool = external_tool_model(context: course_model)
          tool.course_navigation = { enabled: true }
          tool.save
          controller = CoursesController.new
          controller.instance_variable_set(:@context, tool.context)

          Account.site_admin.disable_feature! :assignments_2_teacher

          tabs = controller.sortable_tabs
          tool_tab = tabs.find { |t| Lti::ExternalToolTab.tool_for_tab(t) == tool }
          expect(tool_tab).to be_nil
        end
      end
    end
  end

  describe "#format_course_section_date" do
    it "returns formatted date when date provided" do
      date = Time.zone.parse("January 14, 2019")
      expect(format_course_section_date(date)).to eq "Jan 14, 2019"
    end

    it "returns string (no date) when date not provided" do
      expect(self).to receive(:t).with("#courses.sections.no_date", "(no date)").and_return("(no date)")
      expect(format_course_section_date).to eq "(no date)"
    end
  end

  describe "sortable user course list helpers" do
    context "get_sorting_order" do
      it "returns 'desc' if you click the same column when there is no prior order" do
        expect(get_sorting_order("favorite", "favorite", nil)).to eq("desc")
      end

      it "starts new columns in ascending order" do
        expect(get_sorting_order("published", nil, nil)).to eq("asc")
      end

      it "starts any column you click (that wasn’t already sorted) in ascending order" do
        expect(get_sorting_order("enrolled_as", "favorite", nil)).to eq("asc")
      end

      it "toggles back to 'asc' when you click the same column a second time" do
        expect(get_sorting_order("favorite", "favorite", "desc")).to eq("asc")
      end
    end

    context "get_sorting_icon" do
      it "returns the double arrow icon if we are not sorting on the given column" do
        expect(get_sorting_icon("favorite", "published", "desc")).to eq("icon-mini-arrow-double")
      end

      it "returns the upward arrow icon if we are sorting on the given column in ascending order" do
        expect(get_sorting_icon("favorite", "favorite", nil)).to eq("icon-mini-arrow-up")
      end

      it "returns the downward arrow icon if we are sorting on the given column in descending order" do
        expect(get_sorting_icon("favorite", "favorite", "desc")).to eq("icon-mini-arrow-down")
      end
    end

    context "get_courses_params" do
      it "returns the correct params for the given table" do
        table = "cc"
        column = "favorite"
        old_params = ActionController::Parameters.new
        new_params = ActionController::Parameters.new(cc_sort: column, cc_order: "asc", focus: table)
        expect(get_courses_params(table, column, old_params)).to eq(new_params.permit(:cc_sort, :cc_order, :focus))
      end

      it "returns the correct params for the given table and params for other tables" do
        table = "cc"
        column = "favorite"
        old_params = ActionController::Parameters.new(pc_sort: "published")
        new_params = ActionController::Parameters.new(cc_sort: column, cc_order: "asc", focus: table, pc_sort: "published")
        expect(get_courses_params(table, column, old_params)).to eq(new_params.permit(:cc_sort, :cc_order, :focus, :pc_sort))
      end

      it "only returns permitted params" do
        table = "cc"
        column = "favorite"
        old_params = ActionController::Parameters.new(foo: "bar")
        new_params = ActionController::Parameters.new(cc_sort: column, cc_order: "asc", focus: table)
        expect(get_courses_params(table, column, old_params)).to eq(new_params.permit(:cc_sort, :cc_order, :focus))
      end

      it "works on pc table" do
        table = "pc"
        column = "favorite"
        old_params = ActionController::Parameters.new(pc_sort: column, pc_order: nil, focus: table)
        new_params = ActionController::Parameters.new(pc_sort: column, pc_order: "desc", focus: table)
        expect(get_courses_params(table, column, old_params)).to eq(new_params.permit(:pc_sort, :pc_order, :focus))
      end
    end
  end

  describe "#recent_event_url" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.account.enable_feature!(:discussion_checkpoints)
      @assignment = @course.assignments.create!(assignment_valid_attributes.merge({ points_possible: 10,
                                                                                    submission_types: "online_text_entry" }))
      @checkpoint_topic, @checkpoint_entry = graded_discussion_topic_with_checkpoints(context: @course)
    end

    it "returns url for the parent assignment when event is SubAssignment" do
      expect(recent_event_url(@checkpoint_topic)).to eq "/courses/#{@course.id}/assignments/#{@checkpoint_topic.parent_assignment.id}"
      expect(recent_event_url(@checkpoint_entry)).to eq "/courses/#{@course.id}/assignments/#{@checkpoint_entry.parent_assignment.id}"
    end

    it "returns url for the assignment itself when event is Assignment" do
      expect(recent_event_url(@assignment)).to eq "/courses/#{@course.id}/assignments/#{@assignment.id}"
    end
  end
end

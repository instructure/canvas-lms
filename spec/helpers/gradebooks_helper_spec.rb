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

require "nokogiri"

describe GradebooksHelper do
  include TextHelper

  before do
    stub_const("FakeAssignment",
               Struct.new(:grading_type,
                          :quiz,
                          :points_possible,
                          :anonymous_grading) do
                 def anonymous_grading?
                   anonymous_grading
                 end
               end)

    stub_const("FakeSubmission",
               Struct.new(:assignment,
                          :score,
                          :grade,
                          :submission_type,
                          :workflow_state,
                          :cached_quiz_lti,
                          :excused?))

    stub_const("FakeQuiz",
               Struct.new(:survey, :anonymous_submissions) do
                 def survey?
                   survey
                 end

                 def anonymous_survey?
                   survey? && anonymous_submissions
                 end
               end)
  end

  let(:assignment) { FakeAssignment.new }
  let(:submission) { FakeSubmission.new(assignment) }
  let(:quiz) { assignment.quiz = FakeQuiz.new }
  let(:anonymous_survey) { assignment.quiz = FakeQuiz.new(true, true) }

  describe "#anonymous_survey?" do
    it "requires a quiz" do
      expect(helper.anonymous_survey?(assignment)).to be false
    end

    it "is falsy with just a survey" do
      quiz.survey = true
      expect(helper.anonymous_survey?(assignment)).to be false
    end

    it "is falsy with just anonymous_submissions" do
      quiz.anonymous_submissions = true
      expect(helper.anonymous_survey?(assignment)).to be false
    end

    it "is truthy with an anonymous survey" do
      anonymous_survey
      expect(helper.anonymous_survey?(assignment)).to be true
    end
  end

  describe "#force_anonymous_grading?" do
    it "returns false by default" do
      expect(helper.force_anonymous_grading?(assignment_model)).to be false
    end

    it "returns true if anonymous quiz" do
      anonymous_survey
      expect(helper.force_anonymous_grading?(assignment)).to be true
    end

    it "returns true for an anonymously-graded assignment" do
      assignment = assignment_model
      allow(assignment).to receive(:anonymize_students?).and_return(true)
      expect(helper.force_anonymous_grading?(assignment)).to be true
    end

    it "returns false for a non-anonymously-graded assignment" do
      assignment = assignment_model
      allow(assignment).to receive(:anonymize_students?).and_return(false)
      expect(helper.force_anonymous_grading?(assignment)).to be false
    end
  end

  describe "#force_anonymous_grading_reason" do
    it "returns nothing if anonymous grading is not forced" do
      expect(helper.force_anonymous_grading_reason(assignment_model)).to eq ""
    end

    it "returns anonymous survey reason" do
      anonymous_survey
      expect(helper.force_anonymous_grading_reason(assignment)).to match(/anonymous survey/)
    end

    it "returns anonymous grading" do
      assignment = assignment_model
      allow(assignment).to receive(:anonymize_students?).and_return(true)
      expect(helper.force_anonymous_grading_reason(assignment)).to match(/anonymous grading/)
    end
  end

  describe "#student_score_display_for(submission, can_manage_grades)" do
    let(:score_display) { helper.student_score_display_for(submission) }
    let(:parsed_display) { Nokogiri::HTML5(score_display) }
    let(:score_icon) { parsed_display.at_css("i") }
    let(:score_screenreader_text) { parsed_display.at_css(".screenreader-only").text }

    context "when the supplied submission is nil" do
      it "must return a dash" do
        score = helper.student_score_display_for(nil)
        expect(score).to eq "-"
      end
    end

    context "when the submission has been graded" do
      before do
        submission.score = 1
        submission.grade = 1
      end

      context "and the assignment is graded pass-fail" do
        before do
          assignment.grading_type = "pass_fail"
        end

        context "with a passing grade" do
          before do
            submission.score = 1
          end

          it "must give us a check icon" do
            expect(score_icon["class"]).to include "icon-check"
          end

          it "must indicate the assignment is complete via alt text" do
            expect(score_screenreader_text).to include "Complete"
          end
        end

        context "with a faililng grade" do
          before do
            submission.grade = "incomplete"
            submission.score = nil
          end

          it "must give us a check icon" do
            expect(score_icon["class"]).to include "icon-x"
          end

          it "must indicate the assignment is complete via alt text" do
            expect(score_screenreader_text).to include "Incomplete"
          end
        end
      end

      context "and the assignment is a percentage grade" do
        it "must output the percentage" do
          assignment.grading_type = "percent"
          submission.grade = "42.5"
          expect(score_display).to eq "42.5%"
        end
      end

      context "and the assignment is a point grade" do
        it "must output the grade rounded to two decimal points" do
          assignment.grading_type = "points"
          submission.grade = "42.3542"
          submission.score = 42.3542
          expect(score_display).to eq "42.35"
        end
      end

      context "and the assignment is a letter grade" do
        # clearly this code needs to change; just look at this nonsensical expectation:
        it "has no score_display" do
          assignment.grading_type = "letter_grade"
          submission.grade = "B"
          submission.score = 83
          expect(score_display).to be_nil
        end
      end

      context "and the assignment is a gpa scaled grade" do
        # clearly this code needs to change; just look at this nonsensical expectation:
        it "has no score_display" do
          assignment.grading_type = "gpa_scale"
          submission.grade = "B"
          submission.score = 83
          expect(score_display).to be_nil
        end
      end
    end

    context "when the submission is ungraded" do
      before do
        submission.score = nil
        submission.grade = nil
      end

      context "and the submission is an online submission type" do
        it "must output an appropriate icon" do
          submission.submission_type = "online_quiz"
          expect(score_icon["class"]).to include "submission_icon"
        end
      end

      context "and the submission is some unknown type" do
        it "must output a dash" do
          submission.submission_type = "bogus_type"
          expect(score_display).to eq "-"
        end
      end

      context "and the submission is a pending new quiz" do
        before do
          submission.cached_quiz_lti = true
          submission.workflow_state = Submission.workflow_states.pending_review
          submission.submission_type = "basic_lti_launch"
        end

        it "uses the new quizzes icon" do
          expect(score_display).to eq(
            "<i class=\"submission_icon icon-quiz icon-Solid\" aria-hidden=\"true\"></i><span class=\"screenreader-only\">New Quizzes Submission</span>"
          )
        end
      end

      it "shows an 'annotate' icon when the submission is a student annotation" do
        submission.submission_type = "student_annotation"
        expect(score_icon["class"]).to include "icon-annotate"
      end
    end
  end

  describe "#graded_by_title" do
    it "returns an I18n translated string" do
      expect(I18n).to receive(:t).with(
        "%{graded_date} by %{grader}",
        graded_date: "the_date",
        grader: "the_grader"
      ).and_return("the return value")
      expect(TextHelper).to receive(:date_string).with("the_date").and_return("the_date")
      helper.graded_by_title("the_date", "the_grader")
    end
  end

  describe "#history_submission_class" do
    it "returns a class based on given submission" do
      submission = OpenStruct.new(assignment_id: "assignment_id", user_id: "user_id")
      expect(
        helper.history_submission_class(submission)
      ).to eq "assignment_assignment_id_user_user_id_current_grade"
    end
  end

  describe "translated_due_date_for_speedgrader" do
    before do
      @current_user = user_factory
      @course = Account.default.courses.create!(name: "My Course")
      @course.enroll_teacher(@current_user, enrollment_state: "active")
      @student1 = student_in_course(course: @course, active_all: true).user
      @student2 = student_in_course(course: @course, active_all: true).user
    end

    it "produces a translated due date if multiple dates" do
      assignment = @course.assignments.create!(
        title: "My Multiple Due Date Assignment",
        due_at: "2021-04-15T22:00:24Z"
      )
      section1 = CourseSection.create!(name: "Section 1", course: @course)
      section2 = CourseSection.create!(name: "Section 2", course: @course)
      student_in_section(section1, user: @student1)
      student_in_section(section2, user: @student2)
      assignment.assignment_overrides.create!(
        due_at: "2021-04-15T22:00:24Z",
        due_at_overridden: true,
        set: section1
      )
      assignment.assignment_overrides.create!(
        due_at: "2021-04-22T22:00:24Z",
        due_at_overridden: true,
        set: section2
      )
      expect(translated_due_date_for_speedgrader(assignment)).to eq "Due: Multiple Due Dates"
    end

    it "produces a translated due date based on due date" do
      assignment = @course.assignments.create!(
        title: "My Due Date Assignment",
        due_at: "2021-04-15T22:00:24Z"
      )
      expect(translated_due_date_for_speedgrader(assignment)).to eq "Due: Apr 15, 2021 at 10pm"
    end

    it "produces No due date message if no due date" do
      assignment = @course.assignments.create!(
        title: "My Assignment with no due date",
        due_at: nil
      )
      expect(translated_due_date_for_speedgrader(assignment)).to eq "Due: No Due Date"
    end

    it "produces a translated due date based on single section overriden due date" do
      assignment = @course.assignments.create!(
        title: "My Single Section Overridden Due Date Assignment",
        only_visible_to_overrides: true,
        workflow_state: "published"
      )
      single_section = CourseSection.create!(name: "Single Section", course: @course)
      student_in_section(single_section, user: @student1)
      assignment.assignment_overrides.create!(
        due_at: "2021-04-15T22:00:24Z",
        due_at_overridden: true,
        set: single_section,
        workflow_state: "active"
      )
      assignment.reload
      expect(translated_due_date_for_speedgrader(assignment)).to eq "Due: Apr 15, 2021 at 10pm"
    end
  end
end

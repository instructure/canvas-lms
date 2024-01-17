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

require_relative "../../helpers/speed_grader_common"
require_relative "../../helpers/gradebook_common"

describe "speed grader" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include SpeedGraderCommon

  before(:once) do
    @course = course_factory(active_all: true)
    outcome_with_rubric(course: @course)
    @assignment = @course.assignments.create!(
      name: "assignment with rubric",
      points_possible: 10,
      moderated_grading: true,
      grader_count: 1
    )
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
    @submission = student_submission(assignment: @assignment)
  end

  before do
    stub_kaltura
  end

  shared_examples_for "moderated grading" do
    def add_rubric_assessment(score, comment)
      scroll_into_view(".toggle_full_rubric")
      f(".toggle_full_rubric").click
      expect(f("#rubric_full")).to be_displayed
      expand_right_pane
      wait_for_ajaximations
      driver.execute_script(%(document.querySelector('svg[name="IconFeedback"]').parentElement.click()))
      f("textarea[data-selenium='criterion_comments_text']").send_keys(comment)
      wait_for_ajaximations
      f('td[data-testid="criterion-points"] input').send_keys(score.to_s)
      f('td[data-testid="criterion-points"] input').send_keys(:tab)
      wait_for_ajaximations
      scroll_to(f(".save_rubric_button"))
      save_rubric_button = f("#rubric_full .save_rubric_button")
      save_rubric_button.click
      wait_for_ajaximations
    end

    it "creates provisional grades and submission comments" do
      @submission.find_or_create_provisional_grade!(@user, score: 7)
      @submission.add_comment(commenter: @user, comment: "wat", provisional: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#grading-box-extended")).to have_attribute("value", "7")
      expect(f("#discussion span.comment").text).to include "wat"

      time = 5.minutes.from_now
      Timecop.freeze(time) do
        replace_content f("#grading-box-extended"), "8", tab_out: false
        f(".gradebookHeader--rightside").click
      end
      wait_for_ajaximations
      provisional_grade = @submission.provisional_grades.find_by!(scorer: @user)
      expect(provisional_grade.grade).to eq "8"

      time2 = 10.minutes.from_now
      Timecop.freeze(time2) do
        submit_comment "srsly"
      end
      @submission.reload
      expect(@submission.updated_at.to_i).to eq time2.to_i

      @submission.reload
      expect(@submission.score).to be_nil

      pg = @submission.provisional_grade(@user)
      expect(pg.score.to_i).to be 8
      expect(pg.submission_comments.map(&:comment)).to include "srsly"
    end

    it "creates rubric assessments for the provisional grade" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      comment = "some silly comment"
      time = 5.minutes.from_now
      Timecop.freeze(time) do
        add_rubric_assessment(3, comment)
        expect(f("#rubric_summary_container caption")).to include_text(@rubric.title)
        expect(fj(".rating-tier.selected:visible")).to include_text(comment)
      end

      @submission.reload
      expect(@submission.updated_at.to_i).to eq time.to_i # should get touched

      ra = @association.rubric_assessments.first
      expect(ra.artifact).to be_a(ModeratedGrading::ProvisionalGrade)
      expect(ra.artifact.score).to eq 3
      expect(ra.data[0][:comments]).to eq comment

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#rubric_summary_container")).to include_text(@rubric.title)
      expect(f("#rubric_summary_container")).to include_text(comment)
    end
  end

  context "as a moderator" do
    before do
      course_with_teacher_logged_in(course: @course, active_all: true)
      @moderator = @teacher
      @is_moderator = true
    end

    include_examples "moderated grading"
  end

  context "as a provisional grader" do
    before do
      course_with_ta_logged_in(course: @course, active_all: true)
      @is_moderator = false
    end

    include_examples "moderated grading"

    it "does not lock a provisional grader out if graded by self" do
      @assignment.moderation_graders.create!(user: @ta, anonymous_id: "12345")
      @submission.find_or_create_provisional_grade!(@ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#grading-box-extended")).to be_displayed
      expect(f("#not_gradeable_message")).to_not be_displayed
    end

    it "locks a provisional grader out if graded by someone else" do
      other_ta = course_with_ta(course: @course, active_all: true).user
      @assignment.grade_student(@student, grader: other_ta, provisional: true, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#grading-box-extended")).not_to be_displayed
      expect(f("#not_gradeable_message")).to be_displayed
    end

    it "locks a provisional grader out if graded by someone else while switching students" do
      other_ta = course_with_ta(course: @course, active_all: true).user
      student_submission

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f("#speedgrader_iframe")
      # not locked yet
      expect(f("#grading-box-extended")).to be_displayed
      expect(f("#not_gradeable_message")).to_not be_displayed

      # go to next student
      f("#next-student-button").click
      wait_for_ajaximations

      # create a mark for the first student
      @assignment.grade_student(@student, grader: other_ta, provisional: true, score: 7)

      # go back
      f("#prev-student-button").click
      wait_for_ajaximations

      # should be locked now
      expect(f("#grading-box-extended")).to_not be_displayed
      expect(f("#not_gradeable_message")).to be_displayed
    end

    it "does not lock a provisional grader out if someone else graded but more grader slots are available" do
      @assignment.update_attribute :grader_count, 2
      other_ta = course_with_ta(course: @course, active_all: true).user
      @assignment.moderation_graders.create!(user: other_ta, anonymous_id: "12345")
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#grading-box-extended")).to be_displayed
      expect(f("#not_gradeable_message")).to_not be_displayed
    end

    it "does not lock a provisional grader out if someone else graded but grader is final grader" do
      @assignment.update_attribute :final_grader, @ta
      other_ta = course_with_ta(course: @course, active_all: true).user
      @assignment.moderation_graders.create!(user: other_ta, anonymous_id: "12345")
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#grading-box-extended")).to be_displayed
      expect(f("#not_gradeable_message")).to_not be_displayed
    end
  end
end

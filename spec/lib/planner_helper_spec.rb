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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PlannerHelper do
  context "on a submission" do
    before(:once) do
      student_in_course(active_all: true)
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
      @assignment.publish

      @discussion_assignment = @course.assignments.create!(title: 'graded discussion assignment', due_at: 1.day.from_now, points_possible: 10)
      @discussion = @course.discussion_topics.create!(assignment: @discussion_assignment, title: 'graded discussion')
      @discussion.publish

      @quiz = generate_quiz(@course)
      @quiz2 = generate_quiz(@course)

      @assignment_po = planner_override_model(user: @student, plannable: @assignment, marked_complete: false)
      @discussion_po = planner_override_model(user: @student, plannable: @discussion, marked_complete: false)
      @quiz_po = planner_override_model(user: @student, plannable: @quiz, marked_complete: false)
      @quiz2_po = planner_override_model(user: @student, plannable: @quiz2, marked_complete: false)
    end

    describe "#completes_planner_item_for_submission" do
      it "completes an assignment override" do
        @assignment.submit_homework(@student, body: 'hello world')
        @assignment_po.reload
        expect(@assignment_po.marked_complete).to be_truthy
      end

      it "completes a discussion override" do
        @discussion.reply_from(:user => @student, :text => "reply")
        @discussion_po.reload
        expect(@discussion_po.marked_complete).to be_truthy
      end

      it "completes a quiz override" do
        qsub = generate_quiz_submission(@quiz, student: @student)
        qsub.submission.save!
        @quiz_po.reload
        expect(@quiz_po.marked_complete).to be_truthy
      end

      it "completes an autograded quiz override" do
        qsub = graded_submission(@quiz2, @student)
        @quiz2_po.reload
        expect(@quiz2_po.marked_complete).to be_truthy
      end
    end

    describe "#complete_planner_item_for_quiz_submission" do
      it "completes an ungraded survey override" do
        survey = @course.quizzes.create!(:title => "survey", :due_at => 1.day.from_now, :quiz_type => "survey")
        survey_po = planner_override_model(user: @student, plannable: survey, marked_complete: false)
        sub = survey.generate_submission(@user)
        Quizzes::SubmissionGrader.new(sub).grade_submission
        survey_po.reload
        expect(survey_po.marked_complete).to be_truthy
      end

      it "creates completed override when ungraded survey is submitted" do
        survey = @course.quizzes.create!(:title => "survey", :due_at => 1.day.from_now, :quiz_type => "survey")
        sub = survey.generate_submission(@user)
        Quizzes::SubmissionGrader.new(sub).grade_submission
        survey_po = PlannerOverride.find_by(user: @student, plannable: survey)
        expect(survey_po.marked_complete).to be_truthy
      end
    end
  end
end

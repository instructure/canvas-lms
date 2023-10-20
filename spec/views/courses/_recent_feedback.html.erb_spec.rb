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

require_relative "../views_helper"

describe "courses/_recent_feedback" do
  before do
    course_with_student(active_all: true)
    assign(:current_user, @user)
    submission_model
  end

  it "shows the context when asked to" do
    @assignment.grade_student(@user, grade: 7, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false, show_context: true }

    expect(response.body).to include(@course.short_name)
  end

  it "doesn't show the context when not asked to" do
    @assignment.grade_student(@user, grade: 7, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", contexts: [@course], object: @submission, locals: { is_hidden: false }

    expect(response.body).to_not include(@course.name)
  end

  it "shows the comment" do
    @assignment.update_submission(@user, comment: "bunch of random stuff", commenter: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }

    expect(response.body).to include("bunch of random stuff")
  end

  it "shows the grade" do
    @assignment.update!(points_possible: 5_782_394)
    @assignment.grade_student(@user, grade: 5_782_394, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }

    expect(response.body).to include("5,782,394 out of 5,782,394")
  end

  context "when restrict_quantitative_data is truthy" do
    before :once do
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # truthy setting
      Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
      Account.default.save!
    end

    it "preserves complete / incomplete grade" do
      @assignment.update!(grading_type: "pass_fail")
      @assignment.grade_student(@user, grade: "complete", grader: @teacher)
      @submission.reload
      render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }
      expect(response.body).to include("Complete")
    end

    it "preserves letter-grade" do
      @assignment.update!(grading_type: "letter_grade")
      @assignment.update!(points_possible: 10)
      @assignment.grade_student(@user, grade: "10", grader: @teacher)
      @submission.reload
      render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }
      expect(response.body).to include("A")
    end

    it "coerces points to letter-grade" do
      @assignment.update!(grading_type: "points")
      @assignment.update!(points_possible: 10)
      @assignment.grade_student(@user, grade: "10", grader: @teacher)
      @submission.reload
      render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }
      expect(response.body).to include("A")
    end
  end

  it "shows the grade and the comment" do
    @assignment.update!(points_possible: 25_734)
    @assignment.grade_student(@user, grade: 25_734, grader: @teacher)
    @assignment.update_submission(@user, comment: "something different", commenter: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }

    expect(response.body).to include("25,734 out of 25,734")
    expect(response.body).to include("something different")
  end

  it "contains the new url when assignments 2 student view is enabled" do
    @course.enable_feature!(:assignments_2_student)
    @assignment.update!(points_possible: 25_734)
    @assignment.grade_student(@user, grade: 25_734, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }
    url = context_url(@assignment.context, :context_assignment_url, id: @assignment.id)
    expect(response.body).to include("\"#{url}\"")
  end

  it "contains the old url when assignments 2 student view is disabled" do
    @assignment.update!(points_possible: 25_734)
    @assignment.grade_student(@user, grade: 25_734, grader: @teacher)
    @submission.reload

    assign(:current_user, @user)

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }
    url = context_url(@assignment.context, :context_assignment_submission_url, assignment_id: @assignment.id, id: @user.id)
    expect(response.body).to include("\"#{url}\"")
  end

  it "contains student's url when observer is viewing the student" do
    student = @user
    observer = user_factory

    @assignment.update!(points_possible: 25_734)
    @assignment.grade_student(student, grade: 25_734, grader: @teacher)
    @submission.reload

    assign(:user, student)
    assign(:current_user, observer)

    render partial: "courses/recent_feedback", object: @submission, locals: { is_hidden: false }
    url = context_url(@assignment.context, :context_assignment_submission_url, assignment_id: @assignment.id, id: student.id)
    expect(response.body).to include("\"#{url}\"")
  end
end

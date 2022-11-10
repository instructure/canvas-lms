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

require_relative "../../views_helper"

describe "quizzes/quizzes/_quiz_right_side" do
  it "renders" do
    course_with_student
    view_context
    assign(:quiz, @course.quizzes.create!)
    render partial: "quizzes/quizzes/quiz_right_side"
    expect(response).not_to be_nil
  end

  context "when post policies is enabled" do
    before do
      course_with_student
      view_context

      quiz_with_graded_submission([], user: @student, course: @course)
    end

    let(:quiz) { @quiz }
    let(:quiz_submission) { @quiz_submission }
    let(:assignment) { @assignment }

    it "displays the current score if the submission is posted" do
      assign(:quiz, quiz)
      assign(:submission, quiz_submission)
      render partial: "quizzes/quizzes/quiz_right_side"
      expect(response).to include "Current Score"
    end

    it "does not display the current score if the submission is not posted" do
      quiz_submission.submission.update!(posted_at: nil)
      assign(:quiz, quiz)
      assign(:submission, quiz_submission)

      render partial: "quizzes/quizzes/quiz_right_side"
      expect(response).not_to include "Current Score"
    end
  end
end

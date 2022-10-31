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

describe "quizzes/quizzes/take_quiz" do
  it "renders" do
    course_with_student
    view_context
    quiz = assign(:quiz, @course.quizzes.create!(description: "Hello"))
    sub = assign(:submission, quiz.generate_submission(@user))
    assign(:quiz_presenter, Quizzes::TakeQuizPresenter.new(
                              quiz,
                              sub,
                              params
                            ))
    render "quizzes/quizzes/take_quiz"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.css("#quiz-instructions").first.content.strip).to eq "Hello"
    expect(response).not_to be_nil
  end

  it "renders preview alert for unpublished quiz" do
    course_with_student
    view_context
    quiz = assign(:quiz, @course.quizzes.create!)
    sub = assign(:submission, quiz.generate_submission(@user))
    sub.update_attribute(:workflow_state, "preview")
    assign(:quiz_presenter, Quizzes::TakeQuizPresenter.new(
                              quiz,
                              sub,
                              params
                            ))
    render "quizzes/quizzes/take_quiz"

    expect(response).to include "preview of the draft version"
  end

  it "renders preview alert for published quiz" do
    course_with_student
    view_context
    quiz = @course.quizzes.create!
    quiz.publish!
    assign(:quiz, quiz)
    sub = assign(:submission, quiz.generate_submission(@user))
    sub.update_attribute(:workflow_state, "preview")
    assign(:quiz_presenter, Quizzes::TakeQuizPresenter.new(
                              quiz,
                              sub,
                              params
                            ))
    render "quizzes/quizzes/take_quiz"

    expect(response).to include "preview of the published version"
  end

  it "renders timer_autosubmit_disabled value in template" do
    course_with_student
    view_context
    quiz = assign(:quiz, @course.quizzes.create!(description: "Hello"))
    sub = assign(:submission, quiz.generate_submission(@user))
    assign(:quiz_presenter, Quizzes::TakeQuizPresenter.new(
                              quiz,
                              sub,
                              params
                            ))
    render "quizzes/quizzes/take_quiz"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.css(".timer_autosubmit_disabled").first.content.strip).not_to be_nil
    expect(response).not_to be_nil
  end
end

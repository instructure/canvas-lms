# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/quizzes_common"

describe "quizzes observers" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:once) do
    course_with_student(active_all: true)
    course_with_observer(active_all: true, course: @course).update_attribute(:associated_user_id, @student.id)
  end

  before do
    user_session(@observer)
  end

  context "when 'show correct answers after last attempt setting' is on" do
    before do
      quiz_with_submission
      @quiz.update(show_correct_answers: true,
                   show_correct_answers_last_attempt: true,
                   allowed_attempts: 2)
      @quiz.save!
    end

    it "does not show correct answers on first attempt", priority: "1" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@qsub.id}"
      expect(f("#content")).not_to contain_css(".correct_answer")
    end
  end

  it "shows quiz descriptions" do
    @context = @course
    quiz = quiz_model
    description = "some description"
    quiz.description = description
    quiz.save!

    open_quiz_show_page
    expect(f(".description")).to include_text(description)
  end
end

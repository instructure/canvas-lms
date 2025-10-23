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

require_relative "../common"
require_relative "../helpers/quizzes_common"
require_relative "../helpers/assignment_overrides"

describe "Taking a quiz as a student" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before { course_with_student_logged_in }

  context "when the available from date is in the future" do
    before do
      create_quiz_with_due_date(
        unlock_at: default_time_for_unlock_date(1.day.from_now),
        due_at: default_time_for_due_date(2.days.from_now)
      )
    end

    it "prevents taking the quiz", priority: 1 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect(f("#content")).not_to contain_css("#take_quiz_link")
      expect(f(".lock_explanation")).to include_text "This quiz is locked " \
                                                     "until #{format_time_for_view(@quiz.unlock_at)}"
    end
  end

  context "when the available until date is in the past" do
    before do
      create_quiz_with_due_date(
        due_at: default_time_for_due_date(2.days.ago),
        lock_at: default_time_for_lock_date(1.day.ago)
      )
    end

    it "prevents taking the quiz", priority: 1 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect(f("#content")).not_to contain_css("#take_quiz_link")
      expect(f(".lock_explanation")).to include_text "This quiz was locked " \
                                                     "#{format_time_for_view(@quiz.lock_at)}"
    end
  end

  context "when the due date is in the past" do
    before do
      create_quiz_with_due_date(
        due_at: default_time_for_due_date(Time.zone.now.advance(days: -1))
      )
    end

    it "allows taking the quiz", priority: 1 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect(f("#take_quiz_link")).to be_truthy
    end
  end

  context "when the quiz is in a paced course" do
    before do
      @course.update(enable_course_paces: true)
    end

    context "and the available from date is in the future" do
      before do
        create_quiz_with_due_date(
          unlock_at: default_time_for_unlock_date(1.day.from_now),
          due_at: default_time_for_due_date(2.days.from_now)
        )
      end

      it "allows taking the quiz", priority: 1 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f("#take_quiz_link")).to be_truthy
      end
    end

    context "and the available until date is in the past" do
      before do
        create_quiz_with_due_date(
          due_at: default_time_for_due_date(2.days.ago),
          lock_at: default_time_for_lock_date(1.day.ago)
        )
      end

      it "allows taking the quiz", priority: 1 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f("#take_quiz_link")).to be_truthy
      end
    end
  end
end

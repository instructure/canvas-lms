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

describe "taking a quiz" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context "as a student" do
    before(:once) do
      course_with_teacher(active_all: 1)
      course_with_student(course: @course, active_all: 1)
    end

    before { user_session(@student) }

    def auto_submit_quiz(quiz)
      take_and_answer_quiz(submit: false, quiz:, lock_after: 10.seconds)
      verify_times_up_dialog
      expect_new_page_load { close_times_up_dialog }
    end

    def verify_times_up_dialog
      expect(fj("#times_up_dialog:visible", timeout: 10)).to include_text "Time's Up!"
    end

    context "when the quiz has a lock date", custom_timeout: 45 do
      let(:quiz) { quiz_create(course: @course) }

      it 'automatically submits the quiz once the quiz is locked, and does not mark it "late"', priority: "1" do
        skip "Failing Crystalball DEMO-212"
        auto_submit_quiz(quiz)

        verify_quiz_is_locked
        verify_quiz_is_submitted
        verify_quiz_submission_is_not_late
        verify_quiz_submission_is_not_late_in_speedgrader
      end
    end
  end
end

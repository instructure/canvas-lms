#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/quizzes_common'

describe "quizzes question creation with attempts" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  context 'quiz attempts' do
    def fill_out_attempts_and_validate(attempts, alert_text, expected_attempt_text)
      click_settings_tab
      set_value(f('#multiple_attempts_option'), false)
      set_value(f('#multiple_attempts_option'), true)
      set_value(f('#limit_attempts_option'), false)
      set_value(f('#limit_attempts_option'), true)
      replace_content(f('#quiz_allowed_attempts'), attempts)
      wait_for_ajaximations
      alert = driver.switch_to.alert
      expect(alert.text).to eq alert_text
      alert.dismiss
      expect(f('#quiz_allowed_attempts')).to have_attribute('value', expected_attempt_text)
    end

    it "should not allow quiz attempts that are entered with letters", priority: '2', test_id: 206029 do
      skip('fragile')
      fill_out_attempts_and_validate('abc', 'Quiz attempts can only be specified in numbers', '')
    end

    it "should not allow quiz attempts that are more than 3 digits long", priority: '2', test_id: 206030 do
      skip('fragile')
      fill_out_attempts_and_validate('12345', 'Quiz attempts are limited to 3 digits, if you would like to give your students unlimited attempts, do not check Allow Multiple Attempts box to the left', '')
    end

    it "should not allow quiz attempts that are letters and numbers mixed", priority: '2', test_id: 206036 do
      skip('fragile')
      fill_out_attempts_and_validate('31das', 'Quiz attempts can only be specified in numbers', '')
    end

    it "should allow a 3 digit number for a quiz attempt", priority: '2', test_id: 206039 do
      attempts = "123"
      click_settings_tab
      f('#multiple_attempts_option').click
      f('#limit_attempts_option').click
      replace_content(f('#quiz_allowed_attempts'), attempts)
      f('#quiz_time_limit').click
      expect(alert_present?).to be_falsey
      expect(fj('#quiz_allowed_attempts')).to have_attribute('value', attempts) # fj to avoid selenium caching
      expect_new_page_load { f('.save_quiz_button').click }
      expect(Quizzes::Quiz.last.allowed_attempts).to eq attempts.to_i
    end
  end
end

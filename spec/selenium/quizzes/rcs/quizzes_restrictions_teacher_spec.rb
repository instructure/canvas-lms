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

require_relative '../../common'
require_relative '../../helpers/quizzes_common'

describe 'quiz restrictions as a teacher' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before do
    course_with_teacher_logged_in
    enable_all_rcs @course.account
    stub_rcs_config
  end

  context 'restrict access code' do
    let(:access_code) { '1234' }
    let(:quiz_with_access_code) do
      @context = @course
      quiz = quiz_model
      quiz.quiz_questions.create! question_data: true_false_question_data
      quiz.access_code = access_code
      quiz.generate_quiz_data
      quiz.save!
      quiz.reload
    end

    it 'should have a checkbox on the quiz creation page', priority: "1", test_id: 474273 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      expect('#enable_quiz_access_code').to be
    end

    it 'should show a password field when checking the checkbox', priority: "1", test_id: 474274 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      expect(f('#quiz_access_code')).to have_attribute('tabindex', '-1')
      f('#enable_quiz_access_code').click
      expect(f('#quiz_access_code')).to have_attribute('tabindex', '0')
    end

    it 'should not allow a blank restrict access code password', priority: "1", test_id: 474275 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      f('#enable_quiz_access_code').click
      wait_for_ajaximations

      # now try and save it and validate the validation text
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(ffj('.error_text')[1]).to include_text('You must enter an access code')
    end
  end

  context 'filter ip addresses' do
    it 'should have a checkbox on the quiz creation page', priority: "1", test_id: 474278 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      expect('#enable_quiz_ip_filter').to be
    end

    it 'should show a password field when checking the checkbox', priority: "1", test_id: 474279 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      expect(f('#quiz_ip_filter')).to have_attribute('tabindex', '-1')
      f('#enable_quiz_ip_filter').click
      expect(f('#quiz_ip_filter')).to have_attribute('tabindex', '0')
    end

    it 'should not allow a blank ip address', priority: "1", test_id: 474280 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations

      # now try and save it and validate the validation text
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(ffj('.error_text')[1]).to include_text('You must enter a valid IP Address')
    end

    it 'should not accept an invalid ip address when creating a quiz', priority: "1", test_id: 474284 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations
      f('#quiz_ip_filter').send_keys('7')

      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(ffj('.error_text')[1]).to include_text('IP filter is not valid')
    end

    it 'should have a working link to help with ip address filtering', priority: "1", test_id: 474285 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations

      expect(f('#ip_filters_dialog')).not_to be_displayed
      f('a.ip_filtering_link > img').click
      wait_for_ajaximations
      expect(f('#ip_filters_dialog')).to be_displayed
    end
  end
end

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

require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quizzes stats' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'as a teacher' do

    before do
      course_with_teacher_logged_in
    end

    it 'should display quiz statistics', priority: "1", test_id: 270036 do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      click_quiz_statistics_button

      expect(f('#content .question-statistics .question-text')).to include_text("Which book(s) are required for this course?")
    end

    it 'should have a link to the new quiz stats page', priority: "2", test_id: 270037 do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      expect(f('.icon-stats')).to be

      expect(fj('ul.page-action-list')).to include_text('Quiz Statistics')
    end

    context 'teacher preview' do
      it 'should not show a quiz stats button if there was a teacher preview', priority: "2", test_id: 140645 do
        skip_if_safari(:alert)
        quiz_with_new_questions(!:goto_edit)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        # take the quiz
        f('#preview_quiz_button').click
        wait_for_ajaximations
        f('#submit_quiz_button').click
        driver.switch_to.alert.accept

        expect(f('ul.page-action-list')).not_to include_text('Quiz Statistics')
      end

    end

    context 'stats page' do
      before do
        quiz_with_submission
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      end

      ['Student Analysis', 'Item Analysis'].each do |report_type|
        it "should have a item #{report_type} button tooltip", priority: "2", test_id: 270040 do
          expect(fj(".report-generator:contains('#{report_type}')")).not_to include_text('Report has been generated')

          # move mouse over button
          driver.mouse.move_to f('#header')
          wait_for_ajaximations
          expect(fj(".report-generator:contains('#{report_type}')")).to include_text("Generate #{report_type.downcase} report")
        end

        it 'should download a csv when pressing #{report_type} button ', priority: "1", test_id: 270039 do
          skip("QUIZ-5120")
          button = fj(".generate-report:contains('#{report_type}')")
          button.click
          wait_for_ajaximations

          # our env never creates a csv so the best we can do is check for it attempting to download it

          # move away so the tooltip can be recreated
          driver.mouse.move_to f('#header')
          wait_for_ajaximations

          # move mouse back over button
          driver.mouse.move_to button
          wait_for_ajaximations
          expect(fj('.quiz-report-status:contains("Report is being generated")')).to be_present
        end
      end
    end
  end
end

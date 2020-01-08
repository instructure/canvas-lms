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
require_relative '../helpers/assignment_overrides'


describe 'quizzes with draft state' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before(:each) do
    course_with_student_logged_in
    @course.update(name: 'teacher course')
    @course.save!
    @course.reload

    @context = @course
    @quiz = quiz_model
  end

  context 'with a student' do

    context 'with an unpublished quiz' do

      before(:each) do
        @quiz.unpublish!
      end

      it 'shows an error', priority: "1", test_id: 209419 do
        open_quiz_edit_form
        wait_for_ajaximations
        expect(f('#unauthorized_message')).to include_text 'Access Denied'
      end

      it 'can\'t take an unpublished quiz', priority: "1", test_id: 209420 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/take"
        wait_for_ajaximations
        expect(f('#unauthorized_message')).to include_text 'Access Denied'
      end
    end

    context 'when the available date is in the future' do

      before(:each) do
        @quiz.unlock_at = Time.now.utc + 200.seconds
        @quiz.publish!
      end

      it 'shows an error', priority: "1", test_id: 209421 do
        open_quiz_show_page
        wait_for_ajaximations
        expect(f('.lock_explanation')).to include_text 'This quiz is locked'
      end
    end
  end
end

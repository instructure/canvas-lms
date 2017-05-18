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

require_relative "../../common"
require_relative "../../helpers/quizzes_common"
require_relative "../../helpers/assignment_overrides"

describe 'viewing a quiz with variable due dates on the quiz show page' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  context 'as a student in Section A' do
    before(:once) { prepare_vdd_scenario_for_first_student }

    before(:each) do
      user_session(@student1)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows the due dates for Section A', priority: "1", test_id: 315649 do
      validate_quiz_show_page("Due #{format_time_for_view(@due_at_a)}")
    end

    it 'shows the availability dates for Section A', priority: "1", test_id: 315856 do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_a)} "\
        "- #{format_time_for_view(@lock_at_a)}")
    end

    it 'allows taking the quiz', priority: "1", test_id: 282390 do
      expect(f('.take_quiz_button')).to be_displayed
    end
  end

  context 'as a student in Section B' do
    before(:once) { prepare_vdd_scenario_for_second_student }

    before(:each) do
      user_session(@student2)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows its due date', priority: "1", test_id: 315857 do
      validate_quiz_show_page("Due #{format_time_for_view(@due_at_b)}")
    end

    it 'shows its availability dates', priority: "1", test_id: 315859 do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_b)} "\
        "- #{format_time_for_view(@lock_at_b)}")
    end

    it 'prevents taking the quiz', priority: "1", test_id: 324918 do
      expect(f("#content")).not_to contain_css('.take_quiz_button')
    end

    it 'indicates quiz is locked', priority: "1", test_id: 282392 do
      validate_quiz_show_page("This quiz is locked until #{format_time_for_view(@unlock_at_b)}")
    end
  end
end

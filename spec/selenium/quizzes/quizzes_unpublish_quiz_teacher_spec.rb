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

describe 'unpublishing a quiz on the quiz show page' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  def unpublish_quiz_via_ui
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    wait_for_quiz_publish_button_to_populate
    f('#quiz-publish-link').click
    wait_for_ajaximations
  end

  context 'as a teacher' do
    before(:each) do
      course_with_teacher_logged_in
      create_quiz_with_due_date
    end

    it 'performs all expected changes on the page', priority: "1", test_id: 401338 do
      unpublish_quiz_via_ui

      # changes the button's text to |Unpublished|
      driver.mouse.move_to f('#preview_quiz_button')
      expect(f('#quiz-publish-link')).to include_text 'Unpublished'

      # changes the button text on hover to |Publish|
      driver.mouse.move_to f('#quiz-publish-link')
      expect(f('#quiz-publish-link')).to include_text 'Publish'

      # displays the 'This quiz is unpublished' message
      expect(f('.alert .unpublished_warning')).to be_displayed

      # removes links from the right sidebar
      expect(f("ul.page-action-list")).not_to contain_css("li")

      # retains both |Preview| buttons
      expect(ff('#preview_quiz_button').count).to eq 2

      # shows pre-published options when clicking the cog menu tool
      f('.header-group-right a.al-trigger').click
      wait_for_ajaximations

      items = ff('ul#toolbar-1 li.ui-menu-item')
      items_text = []
      items.each { |i| items_text << i.text.split("\n")[0] }

      expect(items_text).to include 'Show Rubric'
      expect(items_text).to include 'Lock this Quiz Now'
      expect(items_text).to include 'Delete'

      expect(items_text).to_not include 'Preview'
      expect(items_text).to_not include 'Show Student Quiz Results'
      expect(items_text).to_not include 'Message Students Who...'
    end
  end
end

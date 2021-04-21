# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative 'page_objects/quizzes_index_page'

# Note that this is old quizzes in Canvas

describe 'quizzes' do
  include_context 'in-process server selenium tests'
  include QuizzesIndexPage

  before(:each) do
    course_with_teacher_logged_in
    @course.save!
    @quiz1 = @course.quizzes.create!(:title => "Math Quiz!")
    user_session(@teacher)
    visit_quizzes_index_page(@course.id)
  end

  it 'shows direct share options' do
    manage_quiz_menu(@quiz1.id).click

    expect(quiz_settings_menu(@quiz1.id).text).to include('Send to...')
    expect(quiz_settings_menu(@quiz1.id).text).to include('Copy to...')
  end
end

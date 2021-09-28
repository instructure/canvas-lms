# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "common"
require_relative "helpers/quizzes_common"
require_relative 'rcs/pages/rce_next_page'

describe "equation editor" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include RCENextPage

  it "should keep cursor position when clicking close" do
    course_with_teacher_logged_in

    quiz_model(course: @course)
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

    wait_for_tiny(f("#quiz_description"))
    type_in_tiny 'textarea', 'foo'
    select_math_equation_from_toolbar
    equation_editor = fj(".mathquill-editor:visible")
    expect(equation_editor).not_to be_nil

    fj('.ui-dialog-titlebar-close:visible').click
    type_in_tiny 'textarea#quiz_description', 'bar'
    f('.save_quiz_button').click

    expect(f('.description')).to include_text 'foobar'
  end
end

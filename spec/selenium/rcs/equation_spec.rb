# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
require_relative "pages/rce_next_page"
describe "equation editor" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include RCENextPage
  it "keeps cursor position when clicking close" do
    course_with_teacher_logged_in
    quiz_model(course: @course)
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
    wait_for_tiny(f("#quiz_description"))
    type_in_tiny "textarea", "foo"
    equation_editor_button.click
    expect(equation_editor_modal_exists?).to be true
    equation_editor_close_button.click
    type_in_tiny "textarea#quiz_description", "bar"
    f(".save_quiz_button").click
    expect(f(".description")).to include_text "foobar"
  end
end

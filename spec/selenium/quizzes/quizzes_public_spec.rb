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
require_relative '../helpers/public_courses_context'

describe "quizzes for a public course" do
  include_context "in-process server selenium tests"
  include_context "public course as a logged out user"
  include QuizzesCommon

  it "should display quizzes list", priority: "1", test_id: 270033 do
    course_quiz(:active)
    @quiz.update(:title => "hey you should see me")

    get "/courses/#{public_course.id}/quizzes"
    validate_selector_displayed('#assignment-quizzes')
    expect(f('#assignment-quizzes')).to include_text(@quiz.title)
  end
end

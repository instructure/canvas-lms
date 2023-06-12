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
#

require_relative "../../views_helper"

describe "quizzes/quizzes/moderate" do
  let(:num_students) { 5 }

  before do
    course_with_teacher
    @students = Array.new(num_students) do |i|
      name = "#{(i + "a".ord).chr}_student"
      course_with_student(name:, course: @course)
      @student
    end
    course_quiz
    view_context
    assign(:students, @students.paginate)
    assign(:quiz, @quiz)
    assign(:submissions, [])
  end

  it "renders" do
    render "quizzes/quizzes/moderate"
    expect(response).not_to be_nil
  end

  it "has filter options" do
    render "quizzes/quizzes/moderate"
    expect(response.inspect).to include "Search people. As you type in this field, the list of people will be automatically filtered to only include those whose names match your input."
  end
end

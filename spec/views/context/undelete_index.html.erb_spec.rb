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

require_relative "../views_helper"

describe "context/undelete_index" do
  before do
    course_with_teacher(active_all: true)
    assign(:context, @course)
  end

  it "renders the undelete link correctly for quizzes" do
    quiz = @course.quizzes.create!
    assign(:deleted_items, [quiz])
    render
    expect(response.body).not_to match(/quizzes:quiz/)
    expect(response.body).to match(/quiz_#{quiz.id}/)
  end
end

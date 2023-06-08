# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe "quizzes" do
  include_context "in-process server selenium tests"

  context "as an admin" do
    it "shows unpublished quizzes to admins without management rights" do
      course_factory(active_all: true)
      quiz = @course.quizzes.create!(title: "quizz")
      quiz.unpublish!

      role = custom_account_role("other admin", account: Account.default)
      account_admin_user_with_role_changes(role:, role_changes: { read_course_content: true })

      user_with_pseudonym(user: @admin)
      user_session(@admin)

      get "/courses/#{@course.id}/quizzes"

      expect(f(".quiz")).to include_text(quiz.title)
    end
  end
end

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/student_planner_page'

describe "teacher planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    Account.default.enable_feature!(:student_planner)
    course_with_teacher(active_all: true, new_user: true, user_name: 'PlannerTeacher', course_name: 'Planner Course')
    @student1 = User.create!(name: 'Student 1')
    @course.enroll_student(@student1).accept!
  end

  context "teacher interaction with ToDoSidebar" do
    before :each do
      @assignment1 = @course.assignments.create({
                                                 name: "Teacher Assignment",
                                                 due_at: Time.zone.now-1.days,
                                                 submission_types: 'online_text_entry'
                                               })
      @submission = @assignment1.submit_homework(@student1, body: "here is my submission")
      user_session(@teacher)
    end

    it "displays todo items in the card view dashboard", priority: "1", test_id: 216397 do
      go_to_dashcard_view

      expect(card_view_todo_items.first).to contain_jqcss("a:contains('Grade #{@assignment1.name}')")
    end

    it "displays todo items in course homepage", priority: "1", test_id: 216397 do
      get "/courses/#{@course.id}"

      expect(card_view_todo_items.first).to contain_jqcss("a:contains('Grade #{@assignment1.name}')")
    end
  end
end

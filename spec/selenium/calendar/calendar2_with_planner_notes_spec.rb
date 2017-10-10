#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:once) do
    # or some stuff we need to click is "below the fold"
    driver.manage.window.maximize

    Account.default.enable_feature!(:student_planner)
    course_with_teacher(active_all: true, new_user: true)
    @student1 = User.create!(name: 'Student 1')
    @course.enroll_student(@student1).accept!
  end



  context "as the student" do
    before :each do
      user_session(@student1)
    end

    it "should show the student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      get '/calendar2'
      wait_for_ajax_requests
      note = f('a.fc-event')
      expect(note.attribute('class')).to include("group_user_#{@student1.id}") # the user calendar
      expect(note).to include_text('Student 1')
      expect(note).to include_text('To Do:')
      expect(note).to include_text('Student To Do')
      expect(note).to contain_css('i.icon-note-light')
    end
    it "should show course calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      get '/calendar2'
      wait_for_ajax_requests
      note = f('a.fc-event')
      expect(note.attribute('class')).to include("group_course_#{@course.id}") # the course calendar
      expect(note).to include_text('Unnamed Course')
      expect(note).to include_text('To Do:')
      expect(note).to include_text('Course To Do')
      expect(note).to contain_css('i.icon-note-light')
    end
  end
end

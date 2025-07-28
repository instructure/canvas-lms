# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe CourseReportsController do
  before :once do
    course_with_teacher(active_all: true)
    @course.update(start_at: "2021-09-30", restrict_enrollments_to_course_dates: true)
    @course.enable_course_paces = true
    @course.save!
    student_in_course(active_all: true)
    course_pace_model(course: @course)
    @student_enrollment = @student.enrollments.first

    @mod1 = @course.context_modules.create! name: "M1"
    @a1 = @course.assignments.create! name: "A1", workflow_state: "active"
    @mod1.add_item id: @a1.id, type: "assignment"

    @mod2 = @course.context_modules.create! name: "M2"
    @a2 = @course.assignments.create! name: "A2", workflow_state: "published"
    @mod2.add_item id: @a2.id, type: "assignment"
    @a3 = @course.assignments.create! name: "A3", workflow_state: "published"
    @mod2.add_item id: @a3.id, type: "assignment"
    @mod2.add_item type: "external_url", title: "External URL", url: "http://localhost"

    @course_pace.course_pace_module_items.each_with_index do |ppmi, i|
      ppmi.update! duration: i * 2
    end

    @course.enable_course_paces = true
    @course.blackout_dates = [BlackoutDate.new({
                                                 event_title: "blackout dates 1",
                                                 start_date: "2021-10-03",
                                                 end_date: "2021-10-03"
                                               })]

    @course.save!
  end

  describe "POST #create" do
    it "creates a course report with associated progress object" do
      user_session(@teacher)
      expect do
        post :create,
             params: {
               course_id: @course.id,
               report_type: "course_pace_docx",
               parameters: { enrollment_ids: [], section_ids: [] }
             },
             as: :json
      end.to change(CourseReport, :count).by(1)

      expect(CourseReport.last.progress).not_to be_nil
    end
  end
end

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
#

require_relative "../../spec_helper"

describe CoursePacing::BulkStudentEnrollmentPacesApiController do
  before :once do
    @course = course_factory(active_all: true)
    @course.enable_course_paces = true
    @course.save!

    @teacher = user_factory
    @course.enroll_teacher(@teacher, enrollment_state: "active")

    @student1 = user_factory(name: "Alice")
    @student2 = user_factory(name: "Charlie")
    @student3 = user_factory(name: "Bob")

    @student_enrollment1 = @course.enroll_student(@student1, enrollment_state: "active")
    @student_enrollment2 = @course.enroll_student(@student2, enrollment_state: "active")
    @student_enrollment3 = @course.enroll_student(@student3, enrollment_state: "active")

    @section1 = @course.course_sections.create!(name: "Section 1")
    @section2 = @course.course_sections.create!(name: "Section 2")

    @student_enrollment2.update!(course_section: @section1)
    @student_enrollment3.update!(course_section: @section2)

    @assignment = @course.assignments.create!(workflow_state: "published", submission_types: "online_upload")
  end

  before do
    user_session(@teacher)
  end

  describe "#student_bulk_pace_edit_view" do
    before do
      allow(CoursePacing::CoursePaceService).to receive(:off_pace_counts_by_user).and_return({})
    end

    it "returns a list of students with default pagination" do
      get :student_bulk_pace_edit_view, params: { course_id: @course.id }
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json).to include("students", "pages", "sections")

      expect(json["students"].size).to be <= 10

      student_ids = json["students"].pluck(:id)
      expect(student_ids).to match_array([@student1.id.to_s, @student2.id.to_s, @student3.id.to_s])

      expect(json["pages"]).to eq(1)

      section_ids = json["sections"].pluck(:id)
      expect(section_ids).to match_array([@section1.id.to_s, @section2.id.to_s, @course.default_section.id.to_s])
    end

    it "filters by pace status if filter_pace_status param is on-pace/off-pace" do
      allow(CoursePacing::CoursePaceService).to receive(:off_pace_counts_by_user).and_return(
        {
          @student2.id => 1,
        }
      )

      get :student_bulk_pace_edit_view, params: { course_id: @course.id, filter_pace_status: "off-pace" }
      json = response.parsed_body

      # We should see only student2
      expect(json["students"].size).to eq(1)
      expect(json["students"].first["id"]).to eq(@student2.id.to_s)

      get :student_bulk_pace_edit_view, params: { course_id: @course.id, filter_pace_status: "on-pace" }
      json = response.parsed_body

      # We should see student1 and student3
      expect(json["students"].size).to eq(2)
      returned_ids = json["students"].pluck(:id)
      expect(returned_ids).to match_array([@student1.id.to_s, @student3.id.to_s])
    end

    it "correctly sorts by names ascending and descending" do
      get :student_bulk_pace_edit_view, params: { course_id: @course.id, sort: "name", order: "asc" }
      json = response.parsed_body

      # Student 1 is Alice
      expect(json["students"].first["name"]).to eq(@student1.name)

      get :student_bulk_pace_edit_view, params: { course_id: @course.id, sort: "name", order: "desc" }
      json = response.parsed_body

      # Student 2 is Charlie
      expect(json["students"].first["name"]).to eq(@student2.name)
    end

    it "marks a student with an overdue override and no submission as off-pace; and a student who submitted as on-pace" do
      student4 = user_factory
      student_enrollment4 = @course.enroll_student(student4, enrollment_state: "active")

      course_pace = @course.course_paces.create!(workflow_state: "active")

      new_module = @course.context_modules.create!(workflow_state: "active")
      tag = @assignment.context_module_tags.create!(
        context_module: new_module,
        context: @course,
        tag_type: "context_module",
        workflow_state: "active"
      )
      course_pace.course_pace_module_items.create!(
        module_item: tag,
        duration: 1
      )

      @student_enrollment1.update!(start_at: 5.days.ago)
      student_enrollment4.update!(start_at: Time.zone.today)

      course_pace.publish
      @assignment.reload

      @assignment.submit_homework(student4, body: "On time submission")

      allow(CoursePacing::CoursePaceService).to receive(:off_pace_counts_by_user).and_return(
        {
          @student1.id => 1
        }
      )
      get :student_bulk_pace_edit_view, params: { course_id: @course.id }
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      student_data_1 = json["students"].find { |s| s["id"] == @student1.id.to_s }
      student_data_4 = json["students"].find { |s| s["id"] == student4.id.to_s }

      expect(student_data_1["paceStatus"]).to eq("off-pace")
      expect(student_data_4["paceStatus"]).to eq("on-pace")
    end
  end
end

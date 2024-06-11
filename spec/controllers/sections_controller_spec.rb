# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe SectionsController do
  describe "user_count" do
    before do
      course_with_teacher_logged_in(active_all: true)
      @section1 = @course.course_sections.create!(name: "Section1")
      @section2 = @course.course_sections.create!(name: "Section2")

      @student1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
      @student2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
    end

    it "should return the user count for each sections in a course" do
      @section1.enroll_user(@student1, "TeacherEnrollment")
      @section1.enroll_user(@student2, "StudentEnrollment")
      @section2.enroll_user(@student1, "StudentEnrollment")

      get "user_count", params: { course_id: @course.id }

      json_response = response.parsed_body

      sec1 = json_response["sections"].find { |s| s["id"] == @section1.id }
      sec2 = json_response["sections"].find { |s| s["id"] == @section2.id }

      expect(sec1["user_count"]).to eq(2)
      expect(sec2["user_count"]).to eq(1)
    end

    it "should exclude sections if the section id is sent in the exclude param" do
      @section1.enroll_user(@teacher, "TeacherEnrollment")
      @section1.enroll_user(@student1, "StudentEnrollment")
      @section2.enroll_user(@student2, "StudentEnrollment")

      get "user_count", params: { course_id: @course.id, exclude: ["section_#{@section1.id}"] }

      json_response = response.parsed_body

      sec1 = json_response["sections"].find { |s| s["id"] == @section1.id }
      sec2 = json_response["sections"].find { |s| s["id"] == @section2.id }

      expect(sec1).to be_nil
      expect(sec2["user_count"]).to eq(1)
    end

    it "should exclude section if name does not match the search term" do
      get "user_count", params: { course_id: @course.id, search: "ion1" }

      json_response = response.parsed_body

      sec1 = json_response["sections"].find { |s| s["id"] == @section1.id }
      sec2 = json_response["sections"].find { |s| s["id"] == @section2.id }

      expect(sec1["user_count"]).to eq(0)
      expect(sec2).to be_nil
    end
  end
end

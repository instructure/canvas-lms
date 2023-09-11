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
#

describe ModuleAssignmentOverridesController do
  before :once do
    Account.site_admin.enable_feature!(:differentiated_modules)
    course_with_teacher(active_all: true, course_name: "Awesome Course")
    @student1 = student_in_course(active_all: true, name: "Student 1").user
    @student2 = student_in_course(active_all: true, name: "Student 2").user
    @student3 = student_in_course(active_all: true, name: "Student 3").user
    @module1 = @course.context_modules.create!(name: "Module 1")
    @section_override1 = @module1.assignment_overrides.create!(set_type: "CourseSection", set_id: @course.course_sections.first)
    @adhoc_override1 = @module1.assignment_overrides.create!(set_type: "ADHOC")
    @adhoc_override1.assignment_override_students.create!(user: @student1)
    @adhoc_override1.assignment_override_students.create!(user: @student2)
    @adhoc_override2 = @module1.assignment_overrides.create!(set_type: "ADHOC")
    @adhoc_override2.assignment_override_students.create!(user: @student3)
  end

  before do
    user_session(@teacher)
  end

  describe "GET 'index'" do
    it "returns a list of module assignment overrides" do
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.length).to be 3

      expect(json[0]["id"]).to be @section_override1.id
      expect(json[0]["context_module_id"]).to be @module1.id
      expect(json[0]["title"]).to eq "Awesome Course"
      expect(json[0]["course_section"]["id"]).to eq @course.course_sections.first.id
      expect(json[0]["course_section"]["name"]).to eq "Awesome Course"

      expect(json[1]["id"]).to be @adhoc_override1.id
      expect(json[1]["context_module_id"]).to be @module1.id
      expect(json[1]["title"]).to eq "No Title"
      expect(json[1]["students"].length).to eq 2
      expect(json[1]["students"][0]["id"]).to eq @student1.id
      expect(json[1]["students"][0]["name"]).to eq "Student 1"
      expect(json[1]["students"][1]["id"]).to eq @student2.id
      expect(json[1]["students"][1]["name"]).to eq "Student 2"

      expect(json[2]["id"]).to be @adhoc_override2.id
      expect(json[2]["context_module_id"]).to be @module1.id
      expect(json[2]["title"]).to eq "No Title"
      expect(json[2]["students"].length).to eq 1
      expect(json[2]["students"][0]["id"]).to eq @student3.id
      expect(json[2]["students"][0]["name"]).to eq "Student 3"
    end

    it "does not include deleted assignment overrides" do
      @adhoc_override2.update!(workflow_state: "deleted")
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.pluck("id")).to contain_exactly(@section_override1.id, @adhoc_override1.id)
    end

    it "returns 404 if the course doesn't exist" do
      get :index, params: { course_id: 0, context_module_id: @module1.id }
      expect(response).to be_not_found
    end

    it "returns 404 if the module is deleted or nonexistent" do
      @module1.update!(workflow_state: "deleted")
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }
      expect(response).to be_not_found

      @module1.assignment_override_students.each(&:delete)
      @module1.assignment_overrides.each(&:delete)
      @module1.delete
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }
      expect(response).to be_not_found
    end

    it "returns 404 if the module is in a different course" do
      course2 = course_with_teacher(active_all: true, user: @teacher).course
      course2.context_modules.create!
      get :index, params: { course_id: course2, context_module_id: @module1.id }
      expect(response).to be_not_found
    end

    it "returns 404 if the differentiated_modules flag is disabled" do
      Account.site_admin.disable_feature!(:differentiated_modules)
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }
      expect(response).to be_not_found
    end

    it "returns unauthorized if the user doesn't have manage_course_content_edit permission" do
      student = student_in_course.user
      user_session(student)
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }
      expect(response).to be_unauthorized
    end
  end
end

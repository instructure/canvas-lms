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

  describe "PUT 'bulk_update'" do
    it "deletes and creates new overrides" do
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "student_ids" => [@student1.id] }] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.active.count).to eq 1
      expect(@module1.assignment_overrides.active.first.set_type).to eq "ADHOC"
      expect(@module1.assignment_overrides.active.first.assignment_override_students.count).to eq 1
      expect(@module1.assignment_overrides.active.first.assignment_override_students.first.user_id).to eq @student1.id
    end

    it "deletes all overrides when none are provided" do
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.active.count).to eq 0
      expect(@module1.assignment_override_students.count).to eq 0
    end

    it "updates existing section overrides" do
      section2 = @course.course_sections.create!(name: "Section 2")
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @section_override1.id, "course_section_id" => section2.id }] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.active.count).to eq 1
      expect(@module1.assignment_overrides.active.first.set_type).to eq "CourseSection"
      expect(@module1.assignment_overrides.active.first.set_id).to eq section2.id
      expect(@module1.assignment_overrides.active.first.title).to eq "Section 2"
    end

    it "updates existing adhoc overrides" do
      student4 = student_in_course(active_all: true, name: "Student 4").user
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @adhoc_override1.id, "student_ids" => [@student3.id, student4.id], "title" => "Accelerated" }] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.active.count).to eq 1
      ao = @module1.assignment_overrides.active.first
      expect(ao.set_type).to eq "ADHOC"
      expect(ao.title).to eq "Accelerated"
      expect(ao.assignment_override_students.active.count).to eq 2
      expect(ao.assignment_override_students.active.pluck(:user_id)).to eq [@student3.id, student4.id]
    end

    it "updates existing adhoc overrides to section overrides" do
      section2 = @course.course_sections.create!(name: "Section 2")
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @adhoc_override1.id, "course_section_id" => section2.id }] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.active.count).to eq 1
      expect(@module1.assignment_overrides.active.first.set_type).to eq "CourseSection"
      expect(@module1.assignment_overrides.active.first.set_id).to eq section2.id
      expect(@module1.assignment_overrides.active.first.title).to eq "Section 2"
    end

    it "updates existing section overrides to adhoc overrides" do
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @section_override1.id, "student_ids" => [@student1.id], "title" => "some students" }] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.active.count).to eq 1
      ao = @module1.assignment_overrides.active.first
      expect(ao.set_type).to eq "ADHOC"
      expect(ao.title).to eq "some students"
      expect(ao.assignment_override_students.active.count).to eq 1
      expect(ao.assignment_override_students.active.pluck(:user_id)).to eq [@student1.id]
    end

    it "updates multiple existing and new overrides" do
      section2 = @course.course_sections.create!(name: "Section 2")
      section3 = @course.course_sections.create!(name: "Section 3")
      student4 = student_in_course(active_all: true, name: "Student 4").user
      request.content_type = "application/json"
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @section_override1.id, "course_section_id" => section2.id },
                                              { "course_section_id" => section3.id },
                                              { "id" => @adhoc_override1.id, "student_ids" => [@student2.id, @student3.id] },
                                              { "student_ids" => [@student1.id, student4.id], "title" => "test" }] }

      expect(response).to have_http_status :no_content
      aos = @module1.assignment_overrides.active
      expect(aos.count).to eq 4
      expect(aos).to include(@section_override1, @adhoc_override1)

      expect(@section_override1.reload.set_type).to eq "CourseSection"
      expect(@section_override1.set_id).to eq section2.id
      expect(@section_override1.title).to eq "Section 2"

      expect(@adhoc_override1.reload.set_type).to eq "ADHOC"
      expect(@adhoc_override1.title).to eq "No Title"
      expect(@adhoc_override1.assignment_override_students.active.pluck(:user_id)).to contain_exactly(@student2.id, @student3.id)

      expect(aos.where(set_id: section3.id, set_type: "CourseSection").first.title).to eq "Section 3"

      new_adhoc_override = aos.where(set_type: "ADHOC").where.not(id: @adhoc_override1.id).first
      expect(new_adhoc_override.title).to eq "test"
      expect(new_adhoc_override.assignment_override_students.active.pluck(:user_id)).to contain_exactly(@student1.id, student4.id)
    end

    it "doesn't make changes if the passed overrides are the same" do
      overrides = @module1.assignment_overrides.to_a
      students = @module1.assignment_override_students.to_a
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @section_override1.id, "course_section_id" => @course.course_sections.first.id },
                                              { "id" => @adhoc_override1.id, "student_ids" => [@student1.id, @student2.id] },
                                              { "id" => @adhoc_override2.id, "student_ids" => [@student3.id] }] }
      expect(response).to have_http_status :no_content
      expect(@module1.assignment_overrides.reload.to_a).to eq overrides
      expect(@module1.assignment_override_students.reload.to_a).to eq students
    end

    it "updates the module's assignment submissions" do
      assignment = @course.assignments.create!(title: "Assignment", points_possible: 10)
      @module1.add_item(assignment)
      @module1.update_assignment_submissions
      expect(assignment.submissions.reload.pluck(:user_id)).to contain_exactly(@student1.id, @student2.id, @student3.id)

      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "id" => @adhoc_override2.id, "student_ids" => [@student3.id] }] }
      expect(response).to have_http_status :no_content
      expect(assignment.submissions.reload.pluck(:user_id)).to contain_exactly(@student3.id)
    end

    it "returns 400 if the overrides parameter is not a list" do
      put :bulk_update, params: { course_id: @course.id, context_module_id: @module1.id, overrides: "hello" }
      expect(response).to be_bad_request
      json = json_parse(response.body)
      expect(json["error"]).to eq "List of overrides required"
    end

    it "returns 400 if an override param is missing data" do
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "something" => 4 }] }
      expect(response).to be_bad_request
      json = json_parse(response.body)
      expect(json["error"]).to eq "id, student_ids, or course_section_id required with each override"
    end

    it "returns 400 if an override param has both students_ids and course_section_id" do
      put :bulk_update, params: { course_id: @course.id,
                                  context_module_id: @module1.id,
                                  overrides: [{ "course_section_id" => 1, "student_ids" => [1, 2] }] }
      expect(response).to be_bad_request
      json = json_parse(response.body)
      expect(json["error"]).to eq "cannot provide course_section_id and student_ids on the same override"
    end

    it "returns 404 if the course doesn't exist" do
      put :bulk_update, params: { course_id: 0, context_module_id: @module1.id, overrides: [] }
      expect(response).to be_not_found
    end

    it "returns 404 if the differentiated_modules flag is disabled" do
      Account.site_admin.disable_feature!(:differentiated_modules)
      put :bulk_update, params: { course_id: @course.id, context_module_id: @module1.id, overrides: [] }
      expect(response).to be_not_found
    end

    it "returns unauthorized if the user doesn't have manage_course_content_edit permission" do
      student = student_in_course.user
      user_session(student)
      put :bulk_update, params: { course_id: @course.id, context_module_id: @module1.id, overrides: [] }
      expect(response).to be_unauthorized
    end
  end
end

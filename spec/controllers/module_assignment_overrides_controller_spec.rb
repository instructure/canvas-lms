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
    @diff_tag_cat = @course.group_categories.create!(context: @course, name: "Differentiation Tags", non_collaborative: true)
    @diff_tag = @course.groups.create!(context: @course, group_category: @diff_tag_cat, name: "Differentiation Tag Group 1", non_collaborative: true)
    @diff_tag_override1 = @module1.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag.id)
  end

  before do
    user_session(@teacher)
  end

  describe "GET 'index'" do
    it "returns a list of module assignment overrides" do
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.length).to be 4

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

      expect(json[3]["id"]).to be @diff_tag_override1.id
      expect(json[3]["context_module_id"]).to be @module1.id
      expect(json[3]["title"]).to eq @diff_tag.name
      expect(json[3]["group"]["id"]).to eq @diff_tag.id
      expect(json[3]["group"]["non_collaborative"]).to eq @diff_tag.non_collaborative
    end

    it "does not include deleted assignment overrides" do
      @adhoc_override2.update!(workflow_state: "deleted")
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.pluck("id")).to contain_exactly(@section_override1.id, @adhoc_override1.id, @diff_tag_override1.id)
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

    it "returns unauthorized if the user doesn't have manage_course_content_edit permission" do
      student = student_in_course.user
      user_session(student)
      get :index, params: { course_id: @course.id, context_module_id: @module1.id }
      expect(response).to be_unauthorized
    end

    describe "differentiation tags" do
      before do
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!
      end

      def returns_non_collaborative_field_for_group_overrides
        get :index, params: { course_id: @course.id, context_module_id: @module1.id }
        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json.length).to be 4
        expect(json[3]["group"]["id"]).to eq @diff_tag_override1.group.id
        expect(json[3]["group"]["non_collaborative"]).to eq @diff_tag_override1.group.non_collaborative
      end

      it "returns differentiation tags for group overrides" do
        returns_non_collaborative_field_for_group_overrides
      end

      context "works with TAs" do
        before do
          @ta = user_factory(active_all: true)
          @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active")

          user_session(@ta)
        end

        it "returns the non_collaborative field for group overrides" do
          returns_non_collaborative_field_for_group_overrides
        end
      end

      context "unauthorized for students" do
        before do
          @tag2 = @course.groups.create!(group_category: @diff_tag_cat, name: "Tag Group 1", non_collaborative: true)
          @student = user_factory(active_all: true)
          @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

          user_session(@student)
        end

        it "returns 400 unauthorized error" do
          put :bulk_update, params: { course_id: @course.id,
                                      context_module_id: @module1.id,
                                      overrides: [{ "group_id" => @tag2.id }] }
          expect(response).to have_http_status :unauthorized
        end
      end
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
      expect(@module1.assignment_overrides.reload.to_a).to match_array(overrides)
      expect(@module1.assignment_override_students.reload.to_a).to match_array(students)
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

    it "returns unauthorized if the user doesn't have manage_course_content_edit permission" do
      student = student_in_course.user
      user_session(student)
      put :bulk_update, params: { course_id: @course.id, context_module_id: @module1.id, overrides: [] }
      expect(response).to be_unauthorized
    end

    context "discussion checkpoints" do
      before do
        @course.account.enable_feature! :discussion_checkpoints
      end

      it "can add a checkpointed discussion with its own overrides to a module with ad-hoc overrides and add even more students" do
        original_override_student = student_in_course(active_all: true, name: "OOS").user
        extra_override_student = student_in_course(active_all: true, name: "EOS").user
        topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            {
              type: "override",
              set_type: "ADHOC",
              student_ids: [original_override_student],
              due_at: 3.days.from_now
            }
          ],
          points_possible: 5
        )
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            {
              type: "override",
              set_type: "ADHOC",
              student_ids: [original_override_student],
              due_at: 3.days.from_now
            }
          ],
          points_possible: 5,
          replies_required: 2
        )
        topic.assignment.only_visible_to_overrides = true
        topic.assignment.save!

        # sanity check, make sure only original_override_student has checkpoint submissions pre-created
        sub_assignment_submission_ids = topic.assignment.sub_assignment_submissions.pluck("user_id")
        expect(sub_assignment_submission_ids).to include original_override_student.id
        expect(sub_assignment_submission_ids).not_to include @student1.id

        @module1.add_item(type: "discussion_topic", id: topic.id)
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "id" => @adhoc_override1.id, "student_ids" => [@student1.id, @student2.id, @student3.id, extra_override_student.id], "title" => "Accelerated" }] }

        expect(response).to have_http_status :no_content
        sub_assignment_submission_ids = topic.assignment.sub_assignment_submissions.pluck("user_id")
        expect(sub_assignment_submission_ids).to include original_override_student.id
        expect(sub_assignment_submission_ids).to include @student1.id
        expect(sub_assignment_submission_ids).to include @student2.id
        expect(sub_assignment_submission_ids).to include @student3.id
        expect(sub_assignment_submission_ids).to include extra_override_student.id
      end
    end

    context "differentiation tags" do
      before do
        @course.account.enable_feature! :assign_to_differentiation_tags
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!
      end

      it "returns 400 if an override param has both students_ids, group_id and course_section_id" do
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "course_section_id" => 1, "student_ids" => [1, 2], "group_id" => 1 }] }
        expect(response).to be_bad_request
        json = json_parse(response.body)
        expect(json["error"]).to eq "cannot provide group_id, course_section_id, and student_ids on the same override"
      end

      it "returns 400 if an override param has both group_id and course_section_id" do
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "course_section_id" => 1, "group_id" => 1 }] }
        expect(response).to be_bad_request
        json = json_parse(response.body)
        expect(json["error"]).to eq "cannot provide group_id and course_section_id on the same override"
      end

      it "returns 400 if an override param has both group_id and student_ids" do
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "student_ids" => [1, 2], "group_id" => 1 }] }
        expect(response).to be_bad_request
        json = json_parse(response.body)
        expect(json["error"]).to eq "cannot provide group_id and student_ids on the same override"
      end

      it "returns 400 if allow_assign_to_differentiation_tags setting is disabled and group_id is present" do
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
        @course.account.save!
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "group_id" => 1 }] }
        expect(response).to be_bad_request
        json = json_parse(response.body)
        expect(json["error"]).to eq "group_id is not allowed as an override"
      end

      def check_bulk_update_response(tag)
        expect(response).to have_http_status :no_content
        expect(@module1.assignment_overrides.active.count).to eq 1
        expect(@module1.assignment_overrides.active.first.set_type).to eq "Group"
        expect(@module1.assignment_overrides.active.first.set_id).to eq tag.id
        expect(@module1.assignment_overrides.active.first.title).to eq tag.name
      end

      def updates_existing_differentiation_tag_group_overrides
        tag2 = @course.groups.create!(group_category: @diff_tag_cat, name: "Tag Group 1", non_collaborative: true)
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "id" => @diff_tag_override1.id, "group_id" => tag2.id }] }
        check_bulk_update_response(tag2)
      end

      def deletes_and_creates_new_differentiation_tag_group_overrides
        tag2 = @course.groups.create!(group_category: @diff_tag_cat, name: "Tag Group 1", non_collaborative: true)
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "group_id" => tag2.id }] }
        check_bulk_update_response(tag2)
      end

      it "updates existing differentiation tag group overrides" do
        updates_existing_differentiation_tag_group_overrides
      end

      it "deletes and creates differentiation tag group overrides" do
        deletes_and_creates_new_differentiation_tag_group_overrides
      end

      context "works with TAs" do
        before do
          @ta = user_factory(active_all: true)
          @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active")

          user_session(@ta)
        end

        it "updates existing differentiation tag group overrides" do
          updates_existing_differentiation_tag_group_overrides
        end

        it "deletes and creates differentiation tag group overrides" do
          deletes_and_creates_new_differentiation_tag_group_overrides
        end
      end

      context "not allowed for students" do
        before do
          @tag2 = @course.groups.create!(group_category: @diff_tag_cat, name: "Tag Group 1", non_collaborative: true)
          @student = user_factory(active_all: true)
          @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

          user_session(@student)
        end

        it "returns 400 unauthorized error" do
          put :bulk_update, params: { course_id: @course.id,
                                      context_module_id: @module1.id,
                                      overrides: [{ "group_id" => @tag2.id }] }
          expect(response).to have_http_status :unauthorized
        end
      end

      it "updates multiple existing and new overrides" do
        section2 = @course.course_sections.create!(name: "Section 2")
        section3 = @course.course_sections.create!(name: "Section 3")
        tag2 = @course.groups.create!(group_category: @diff_tag_cat, name: "Tag Group 2", non_collaborative: true)
        tag3 = @course.groups.create!(group_category: @diff_tag_cat, name: "Tag Group 3", non_collaborative: true)
        student4 = student_in_course(active_all: true, name: "Student 4").user
        request.content_type = "application/json"
        put :bulk_update, params: { course_id: @course.id,
                                    context_module_id: @module1.id,
                                    overrides: [{ "id" => @section_override1.id, "course_section_id" => section2.id },
                                                { "course_section_id" => section3.id },
                                                { "id" => @diff_tag_override1.id, "group_id" => tag2.id },
                                                { "group_id" => tag3.id },
                                                { "id" => @adhoc_override1.id, "student_ids" => [@student2.id, @student3.id] },
                                                { "student_ids" => [@student1.id, student4.id], "title" => "test" }] }
        expect(response).to have_http_status :no_content
        aos = @module1.assignment_overrides.active
        expect(aos.count).to eq 6
        expect(aos).to include(@section_override1, @diff_tag_override1, @adhoc_override1)

        expect(@section_override1.reload.set_type).to eq "CourseSection"
        expect(@section_override1.set_id).to eq section2.id
        expect(@section_override1.title).to eq "Section 2"

        expect(@diff_tag_override1.reload.set_type).to eq "Group"
        expect(@diff_tag_override1.set_id).to eq tag2.id
        expect(@diff_tag_override1.title).to eq tag2.name

        expect(@adhoc_override1.reload.set_type).to eq "ADHOC"
        expect(@adhoc_override1.title).to eq "No Title"
        expect(@adhoc_override1.assignment_override_students.active.pluck(:user_id)).to contain_exactly(@student2.id, @student3.id)

        expect(aos.where(set_id: section3.id, set_type: "CourseSection").first.title).to eq "Section 3"
        expect(aos.where(set_id: tag3.id, set_type: "Group").first.title).to eq tag3.name

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
                                                { "id" => @diff_tag_override1.id, "group_id" => @diff_tag.id },
                                                { "id" => @adhoc_override1.id, "student_ids" => [@student1.id, @student2.id] },
                                                { "id" => @adhoc_override2.id, "student_ids" => [@student3.id] }] }
        expect(response).to have_http_status :no_content
        expect(@module1.assignment_overrides.reload.to_a).to match_array(overrides)
        expect(@module1.assignment_override_students.reload.to_a).to match_array(students)
      end
    end
  end

  describe "PUT 'convert_tag_overrides_to_adhoc_overrides" do
    before do
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @diff_tag_module = @course.context_modules.create!(name: "Differentiation Tag Module")
      @diff_tag_cat = @course.group_categories.create!(name: "Learning Level", non_collaborative: true)
      @diff_tag1 = @course.groups.create!(name: "Honors", group_category: @diff_tag_cat, non_collaborative: true)
      @diff_tag2 = @course.groups.create!(name: "Standard", group_category: @diff_tag_cat, non_collaborative: true)

      # Add student 1 to honors
      @diff_tag1.add_user(@student1, "accepted")

      @diff_tag2.add_user(@student2, "accepted")
      @diff_tag2.add_user(@student3, "accepted")
    end

    def create_diff_tag_override_for_module(context_module, diff_tag)
      context_module.assignment_overrides.create!(set_type: "Group", set: diff_tag)
    end

    context "errors" do
      it "returns 404 if the course doesn't exist" do
        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: (@course.id + 1), context_module_id: @diff_tag_module.id }
        expect(response).to be_not_found
      end

      it "returns 404 if the module is deleted or nonexistent" do
        @diff_tag_module.update!(workflow_state: "deleted")
        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }
        expect(response).to be_not_found
      end

      it "returns 404 if the module is in a different course" do
        course2 = course_with_teacher(active_all: true, user: @teacher).course
        course2.context_modules.create!
        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: course2.id, context_module_id: @diff_tag_module.id }
        expect(response).to be_not_found
      end

      it "returns unauthorized if the user doesn't have manage_course_content_edit permission" do
        student = student_in_course.user
        user_session(student)
        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }
        expect(response).to be_unauthorized
      end

      it "returns bad request if underlying service contains errors" do
        allow(DifferentiationTag::OverrideConverterService).to receive(:convert_tags_to_adhoc_overrides_for).and_return(["Something went wrong"])

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }
        expect(response).to have_http_status :bad_request
        json = json_parse(response.body)
        expect(json["errors"]).to eq ["Something went wrong"]
      end

      it "concatinates errors if multiple issues occur in underlying service" do
        allow(DifferentiationTag::OverrideConverterService).to receive(:convert_tags_to_adhoc_overrides_for).and_return(["Invalid course", "Invalid learning object"])

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }
        expect(response).to have_http_status :bad_request
        json = json_parse(response.body)
        expect(json["errors"]).to eq ["Invalid course", "Invalid learning object"]
      end
    end

    it "converts tag overrides to adhoc overrides" do
      create_diff_tag_override_for_module(@diff_tag_module, @diff_tag1)
      create_diff_tag_override_for_module(@diff_tag_module, @diff_tag2)

      expect(@diff_tag_module.assignment_overrides.active.count).to eq 2
      expect(@diff_tag_module.assignment_overrides.active.pluck(:set_type).uniq).to eq ["Group"]

      put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }

      expect(response).to have_http_status :no_content
      expect(@diff_tag_module.assignment_overrides.active.count).to eq 1
      override = @diff_tag_module.assignment_overrides.active.first
      expect(override.set_type).to eq "ADHOC"
      expect(override.assignment_override_students.count).to eq 3
    end

    it "creates new adhoc override if one already exists" do
      adhoc_override = @diff_tag_module.assignment_overrides.create!(set_type: "ADHOC")
      adhoc_override.assignment_override_students.create!(user: @student1)

      create_diff_tag_override_for_module(@diff_tag_module, @diff_tag1)
      create_diff_tag_override_for_module(@diff_tag_module, @diff_tag2)

      expect(@diff_tag_module.assignment_overrides.active.count).to eq 3

      put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }

      expect(response).to have_http_status :no_content
      adhoc_overrides = @diff_tag_module.assignment_overrides.active.where(set_type: "ADHOC")
      expect(adhoc_overrides.count).to eq 2

      first_adhoc_override = adhoc_overrides.first
      expect(first_adhoc_override.assignment_override_students.count).to eq 1

      second_adhoc_override = adhoc_overrides.second
      expect(second_adhoc_override.assignment_override_students.count).to eq 2
    end

    it "does not interfere with other types of module overrides" do
      create_diff_tag_override_for_module(@diff_tag_module, @diff_tag1)
      create_diff_tag_override_for_module(@diff_tag_module, @diff_tag2)
      @diff_tag_module.assignment_overrides.create!(set_type: "CourseSection", set_id: @course.course_sections.first)

      expect(@diff_tag_module.assignment_overrides.active.count).to eq 3
      expect(@diff_tag_module.assignment_overrides.active.pluck(:set_type).uniq).to contain_exactly("Group", "CourseSection")

      put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }

      expect(response).to have_http_status :no_content
      expect(@diff_tag_module.assignment_overrides.active.count).to eq 2
      expect(@diff_tag_module.assignment_overrides.active.pluck(:set_type).uniq).to contain_exactly("ADHOC", "CourseSection")
    end

    it "does not return error if no tag overrides exist" do
      put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, context_module_id: @diff_tag_module.id }

      expect(response).to have_http_status :no_content
      expect(@diff_tag_module.assignment_overrides.active.count).to eq 0
    end
  end
end

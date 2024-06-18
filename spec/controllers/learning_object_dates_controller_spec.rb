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

describe LearningObjectDatesController do
  before :once do
    Account.site_admin.enable_feature! :selective_release_backend
    Account.site_admin.enable_feature! :selective_release_ui_api
    Account.site_admin.enable_feature! :differentiated_files
    course_with_teacher(active_all: true)
  end

  before do
    user_session(@teacher)
  end

  describe "GET 'show'" do
    before :once do
      @assignment = @course.assignments.create!(
        title: "Locked Assignment",
        due_at: "2022-01-02T00:00:00Z",
        unlock_at: "2022-01-01T00:00:00Z",
        lock_at: "2022-01-03T01:00:00Z",
        only_visible_to_overrides: true
      )
      @override = @assignment.assignment_overrides.create!(course_section: @course.default_section,
                                                           due_at: "2022-02-01T01:00:00Z",
                                                           due_at_overridden: true)
    end

    it "returns date details for an assignment" do
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => @assignment.id,
                                 "due_at" => "2022-01-02T00:00:00Z",
                                 "unlock_at" => "2022-01-01T00:00:00Z",
                                 "lock_at" => "2022-01-03T01:00:00Z",
                                 "only_visible_to_overrides" => true,
                                 "group_category_id" => nil,
                                 "graded" => true,
                                 "visible_to_everyone" => false,
                                 "overrides" => [{
                                   "id" => @override.id,
                                   "assignment_id" => @assignment.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "due_at" => "2022-02-01T01:00:00Z",
                                   "all_day" => false,
                                   "all_day_date" => "2022-02-01",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for a quiz" do
      @quiz = @course.quizzes.create!(title: "quiz", due_at: "2022-01-10T00:00:00Z")
      @override.assignment_id = nil
      @override.quiz_id = @quiz.id
      @override.save!

      get :show, params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => @quiz.id,
                                 "due_at" => "2022-01-10T00:00:00Z",
                                 "unlock_at" => nil,
                                 "lock_at" => nil,
                                 "only_visible_to_overrides" => false,
                                 "graded" => true,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => true,
                                 "overrides" => [{
                                   "id" => @override.id,
                                   "quiz_id" => @quiz.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "due_at" => "2022-02-01T01:00:00Z",
                                   "all_day" => false,
                                   "all_day_date" => "2022-02-01",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for a module" do
      context_module = @course.context_modules.create!(name: "module")
      @override.assignment_id = nil
      @override.context_module_id = context_module.id
      @override.save!

      get :show, params: { course_id: @course.id, context_module_id: context_module.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => context_module.id,
                                 "unlock_at" => nil,
                                 "only_visible_to_overrides" => true,
                                 "visible_to_everyone" => false,
                                 "graded" => false,
                                 "overrides" => [{
                                   "id" => @override.id,
                                   "context_module_id" => context_module.id,
                                   "context_module_name" => "module",
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "due_at" => "2022-02-01T01:00:00Z",
                                   "all_day" => false,
                                   "all_day_date" => "2022-02-01",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for a graded discussion" do
      discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")
      assignment = discussion.assignment
      assignment.update!(due_at: "2022-05-06T12:00:00Z",
                         unlock_at: "2022-05-05T12:00:00Z",
                         lock_at: "2022-05-07T12:00:00Z")
      override = assignment.assignment_overrides.create!(set: @course.default_section,
                                                         due_at: "2022-04-06T12:00:00Z",
                                                         unlock_at: "2022-04-05T12:00:00Z",
                                                         lock_at: "2022-04-07T12:00:00Z",
                                                         due_at_overridden: true,
                                                         unlock_at_overridden: true,
                                                         lock_at_overridden: true)
      get :show, params: { course_id: @course.id, discussion_topic_id: discussion.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => discussion.id,
                                 "due_at" => "2022-05-06T12:00:00Z",
                                 "unlock_at" => "2022-05-05T12:00:00Z",
                                 "lock_at" => "2022-05-07T12:00:00Z",
                                 "only_visible_to_overrides" => false,
                                 "graded" => true,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => true,
                                 "overrides" => [{
                                   "id" => override.id,
                                   "assignment_id" => assignment.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "due_at" => "2022-04-06T12:00:00Z",
                                   "unlock_at" => "2022-04-05T12:00:00Z",
                                   "lock_at" => "2022-04-07T12:00:00Z",
                                   "all_day" => false,
                                   "all_day_date" => "2022-04-06",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for an ungraded discussion" do
      discussion = @course.discussion_topics.create!(title: "ungraded topic",
                                                     unlock_at: "2022-01-05T12:00:00Z",
                                                     lock_at: "2022-03-05T12:00:00Z")
      override = discussion.assignment_overrides.create!(set: @course.default_section,
                                                         lock_at: "2022-01-04T12:00:00Z",
                                                         lock_at_overridden: true)
      get :show, params: { course_id: @course.id, discussion_topic_id: discussion.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => discussion.id,
                                 "unlock_at" => "2022-01-05T12:00:00Z",
                                 "lock_at" => "2022-03-05T12:00:00Z",
                                 "only_visible_to_overrides" => false,
                                 "graded" => false,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => true,
                                 "overrides" => [{
                                   "id" => override.id,
                                   "discussion_topic_id" => discussion.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "lock_at" => "2022-01-04T12:00:00Z",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for an ungraded discussion with a section visibility" do
      discussion = @course.discussion_topics.create!(title: "ungraded topic",
                                                     unlock_at: "2022-01-05T12:00:00Z",
                                                     lock_at: "2022-03-05T12:00:00Z")
      discussion.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
        discussion_topic: @topic,
        course_section: @course.default_section,
        workflow_state: "active"
      )
      discussion.is_section_specific = true
      discussion.save!

      get :show, params: { course_id: @course.id, discussion_topic_id: discussion.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => discussion.id,
                                 "unlock_at" => "2022-01-05T12:00:00Z",
                                 "lock_at" => "2022-03-05T12:00:00Z",
                                 "only_visible_to_overrides" => false,
                                 "graded" => false,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => false,
                                 "overrides" => [{
                                   "discussion_topic_id" => discussion.id,
                                   "course_section_id" => @course.default_section.id,
                                   "unlock_at" => "2022-01-05T12:00:00Z",
                                   "lock_at" => "2022-03-05T12:00:00Z",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for an ungraded discussion with a section visibility and section override" do
      section1 = @course.course_sections.create!
      section2 = @course.course_sections.create!
      discussion = @course.discussion_topics.create!(title: "ungraded topic",
                                                     unlock_at: "2022-01-05T12:00:00Z",
                                                     lock_at: "2022-03-05T12:00:00Z")
      discussion.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
        discussion_topic: @topic,
        course_section: section1,
        workflow_state: "active"
      )

      discussion.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
        discussion_topic: @topic,
        course_section: section2,
        workflow_state: "active"
      )

      discussion.is_section_specific = true
      discussion.save!

      override = discussion.assignment_overrides.create!(set: section1,
                                                         lock_at: "2022-01-04T12:00:00Z",
                                                         lock_at_overridden: true)

      get :show, params: { course_id: @course.id, discussion_topic_id: discussion.id }
      expect(response).to be_successful

      expect(json_parse).to eq({
                                 "id" => discussion.id,
                                 "unlock_at" => "2022-01-05T12:00:00Z",
                                 "lock_at" => "2022-03-05T12:00:00Z",
                                 "only_visible_to_overrides" => false,
                                 "graded" => false,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => false,
                                 "overrides" => [
                                   {
                                     "id" => override.id,
                                     "discussion_topic_id" => discussion.id,
                                     "title" => override.title,
                                     "course_section_id" => section1.id,
                                     "lock_at" => "2022-01-04T12:00:00Z",
                                     "unassign_item" => false
                                   },
                                   {
                                     "discussion_topic_id" => discussion.id,
                                     "course_section_id" => section2.id,
                                     "unlock_at" => "2022-01-05T12:00:00Z",
                                     "lock_at" => "2022-03-05T12:00:00Z",
                                     "unassign_item" => false
                                   }
                                 ]
                               })
    end

    it "returns date details for a regular page" do
      wiki_page = @course.wiki_pages.create!(title: "My Page",
                                             unlock_at: "2022-01-05T00:00:00Z",
                                             lock_at: "2022-03-05T00:00:00Z")
      override = wiki_page.assignment_overrides.create!(set: @course.default_section,
                                                        unlock_at: "2022-01-04T00:00:00Z",
                                                        unlock_at_overridden: true)
      get :show, params: { course_id: @course.id, page_id: wiki_page.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => wiki_page.id,
                                 "unlock_at" => "2022-01-05T00:00:00Z",
                                 "lock_at" => "2022-03-05T00:00:00Z",
                                 "only_visible_to_overrides" => false,
                                 "graded" => false,
                                 "visible_to_everyone" => true,
                                 "overrides" => [{
                                   "id" => override.id,
                                   "wiki_page_id" => wiki_page.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "unlock_at" => "2022-01-04T00:00:00Z",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for a page with an assignment" do
      wiki_page = @course.wiki_pages.create!(title: "My Page",
                                             # dummy params
                                             unlock_at: "2022-01-04T00:00:00Z",
                                             lock_at: "2022-03-04T00:00:00Z",
                                             only_visible_to_overrides: false)
      wiki_page.assignment = @course.assignments.create!(
        name: "My Page",
        submission_types: ["wiki_page"],
        unlock_at: "2022-01-05T00:00:00Z",
        lock_at: "2022-02-05T00:00:00Z",
        only_visible_to_overrides: true
      )
      wiki_page.save!
      override = wiki_page.assignment.assignment_overrides.create!(set: @course.default_section,
                                                                   unlock_at: "2022-01-07T00:00:00Z",
                                                                   unlock_at_overridden: true)
      get :show, params: { course_id: @course.id, page_id: wiki_page.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => wiki_page.id,
                                 "due_at" => nil,
                                 "unlock_at" => "2022-01-05T00:00:00Z",
                                 "lock_at" => "2022-02-05T00:00:00Z",
                                 "only_visible_to_overrides" => true,
                                 "graded" => false,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => false,
                                 "overrides" => [{
                                   "id" => override.id,
                                   "assignment_id" => wiki_page.assignment.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "unlock_at" => "2022-01-07T00:00:00Z",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "returns date details for a file" do
      attachment = @course.attachments.create!(filename: "coolpdf.pdf",
                                               uploaded_data: StringIO.new("test"),
                                               unlock_at: "2022-01-05T00:00:00Z",
                                               lock_at: "2022-03-05T00:00:00Z")
      override = attachment.assignment_overrides.create!(set: @course.default_section,
                                                         unlock_at: "2022-01-04T00:00:00Z",
                                                         unlock_at_overridden: true)
      get :show, params: { course_id: @course.id, attachment_id: attachment.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => attachment.id,
                                 "unlock_at" => "2022-01-05T00:00:00Z",
                                 "lock_at" => "2022-03-05T00:00:00Z",
                                 "only_visible_to_overrides" => false,
                                 "graded" => false,
                                 "visible_to_everyone" => true,
                                 "overrides" => [{
                                   "id" => override.id,
                                   "attachment_id" => attachment.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "unlock_at" => "2022-01-04T00:00:00Z",
                                   "unassign_item" => false
                                 }]
                               })
    end

    it "includes an unassigned assignment override" do
      @override.unassign_item = true
      @override.save!
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_successful
      expect(json_parse).to eq({
                                 "id" => @assignment.id,
                                 "due_at" => "2022-01-02T00:00:00Z",
                                 "unlock_at" => "2022-01-01T00:00:00Z",
                                 "lock_at" => "2022-01-03T01:00:00Z",
                                 "only_visible_to_overrides" => true,
                                 "graded" => true,
                                 "group_category_id" => nil,
                                 "visible_to_everyone" => false,
                                 "overrides" => [{
                                   "id" => @override.id,
                                   "assignment_id" => @assignment.id,
                                   "title" => "Unnamed Course",
                                   "course_section_id" => @course.default_section.id,
                                   "due_at" => "2022-02-01T01:00:00Z",
                                   "all_day" => false,
                                   "all_day_date" => "2022-02-01",
                                   "unassign_item" => true
                                 }]
                               })
    end

    it "includes an assignment's modules' overrides" do
      module1 = @course.context_modules.create!(name: "module 1")
      module1_override = module1.assignment_overrides.create!
      module1.content_tags.create!(content: @assignment, context: @course, tag_type: "context_module")
      module1.content_tags.create!(content: @assignment, context: @course, tag_type: "context_module") # make sure we don't duplicate

      module2 = @course.context_modules.create!(name: "module 2")
      module2_override = module2.assignment_overrides.create!
      module2.content_tags.create!(content: @assignment, context: @course, tag_type: "context_module")

      module3 = @course.context_modules.create!(name: "module 3") # make sure we don't count unrelated modules
      module3.assignment_overrides.create!

      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_successful
      overrides = json_parse["overrides"]
      expect(overrides.pluck("id")).to contain_exactly(@override.id, module1_override.id, module2_override.id)
    end

    it "includes group_category_id on a group assignment" do
      category = @course.group_categories.create(name: "Student Groups")
      @assignment.update!(group_category_id: category.id)

      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_successful
      json = json_parse
      expect(json["group_category_id"]).to eq category.id
    end

    it "paginates overrides" do
      override2 = @assignment.assignment_overrides.create!
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id, per_page: 1 }

      expect(response).to be_successful
      json = json_parse
      expect(json["id"]).to eq @assignment.id
      expect(json["overrides"].length).to eq 1
      expect(json["overrides"][0]["id"]).to eq @override.id

      get :show, params: { course_id: @course.id, assignment_id: @assignment.id, per_page: 1, page: 2 }
      expect(response).to be_successful
      json = json_parse
      expect(json["id"]).to eq @assignment.id
      expect(json["overrides"].length).to eq 1
      expect(json["overrides"][0]["id"]).to eq override2.id
    end

    it "includes student names on ADHOC overrides" do
      student1 = student_in_course(name: "Student 1").user
      student2 = student_in_course(name: "Student 2").user
      @override.update!(set_id: nil, set_type: "ADHOC")
      @override.assignment_override_students.create!(user: student1)
      @override.assignment_override_students.create!(user: student2)

      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_successful
      json = json_parse
      expect(json["overrides"].length).to eq 1
      expect(json["overrides"][0]["student_ids"]).to contain_exactly(student1.id, student2.id)
      expect(json["overrides"][0]["students"]).to contain_exactly({ "id" => student1.id, "name" => "Student 1" },
                                                                  { "id" => student2.id, "name" => "Student 2" })
    end

    it "does not include deleted overrides" do
      @assignment.assignment_overrides.destroy_all
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_successful
      expect(json_parse["overrides"]).to eq []
    end

    it "returns unauthorized for students" do
      course_with_student_logged_in(course: @course)
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_unauthorized
    end

    it "returns unauthorized for modules if user doesn't have manage_course_content_edit permission" do
      RoleOverride.create!(context: @course.account, permission: "manage_course_content_edit", role: teacher_role, enabled: false)
      context_module = @course.context_modules.create!(name: "module")
      get :show, params: { course_id: @course.id, context_module_id: context_module.id }
      expect(response).to be_unauthorized
    end

    it "returns not_found if assignment is deleted" do
      @assignment.destroy!
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_not_found
    end

    it "returns not_found if assignment is not in course" do
      course_with_teacher(active_all: true, user: @teacher)
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_not_found
    end

    it "returns not_found if selective_release_ui_api is disabled" do
      Account.site_admin.disable_feature! :selective_release_ui_api
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_not_found
    end

    it "returns bad_request if attempting to get a file's details and differentiated_files is disabled" do
      Account.site_admin.disable_feature! :differentiated_files
      attachment = @course.attachments.create!(filename: "coolpdf.pdf", uploaded_data: StringIO.new("test"))
      get :show, params: { course_id: @course.id, attachment_id: attachment.id }
      expect(response).to be_bad_request
    end

    context "on blueprint child courses" do
      before :once do
        @child_course = @course
        @child_assignment = @assignment
        master_template = MasterCourses::MasterTemplate.set_as_master_course(course_model)
        child_subscription = master_template.add_child_course!(@child_course)
        MasterCourses::ChildContentTag.create!(child_subscription:, content: @child_assignment)
        @mct = MasterCourses::MasterContentTag.create!(master_template:, content: assignment_model)
        @child_assignment.update! migration_id: @mct.migration_id
      end

      it "returns an empty blueprint_date_locks prop for unlocked child content" do
        get :show, params: { course_id: @child_course.id, assignment_id: @child_assignment.id }
        expect(response).to be_successful
        expect(json_parse).to include({ "blueprint_date_locks" => [] })
      end

      it "returns the proper blueprint_locks for locked child content" do
        @mct.update_attribute(:restrictions, { availability_dates: true })
        get :show, params: { course_id: @child_course.id, assignment_id: @child_assignment.id }
        expect(response).to be_successful
        expect(json_parse).to include({ "blueprint_date_locks" => ["availability_dates"] })
      end
    end
  end

  describe "PUT 'update'" do
    before do
      request.content_type = "application/json"
    end

    shared_examples_for "learning object updates" do |support_due_at|
      it "updates base dates" do
        request_params = { **default_params,
          due_at: "2023-01-02T05:00:00Z",
          unlock_at: "2023-01-01T00:00:00Z",
          lock_at: "2023-01-07T08:00:00Z",
          only_visible_to_overrides: false }
        request_params.delete(:due_at) unless support_due_at
        put :update, params: request_params
        expect(response).to be_no_content
        differentiable.reload
        expect(differentiable.due_at.iso8601).to eq "2023-01-02T05:00:00Z" if support_due_at
        expect(differentiable.unlock_at.iso8601).to eq "2023-01-01T00:00:00Z"
        expect(differentiable.lock_at.iso8601).to eq "2023-01-07T08:00:00Z"
        expect(differentiable.only_visible_to_overrides).to be false
      end

      it "does not touch other object attributes" do
        original_title = learning_object.title
        put :update, params: { **default_params, due_at: "2022-01-02T01:00:00Z" }
        expect(response).to be_no_content
        expect(learning_object.reload.title).to eq original_title
      end

      it "works if only some arguments are passed" do
        differentiable.assignment_overrides.create!(course_section: @course.default_section)
        put :update, params: { **default_params, unlock_at: "2020-01-01T00:00:00Z" }
        expect(response).to be_no_content
        differentiable.reload
        expect(differentiable.unlock_at.iso8601).to eq "2020-01-01T00:00:00Z"
        expect(differentiable.lock_at.iso8601).to eq "2022-01-03T01:00:00Z"
        expect(differentiable.assignment_overrides.active.count).to eq 1
      end

      it "removes overrides" do
        differentiable.assignment_overrides.create!(course_section: @course.default_section)
        put :update, params: { **default_params, assignment_overrides: [] }
        expect(response).to be_no_content
        differentiable.reload
        expect(differentiable.assignment_overrides.active.count).to eq 0
      end

      it "updates overrides" do
        override1 = differentiable.assignment_overrides.create!(course_section: @course.default_section,
                                                                unlock_at: nil,
                                                                unlock_at_overridden: true)
        override1.update!(due_at: "2022-02-01T01:00:00Z", due_at_overridden: true) if support_due_at
        override2 = differentiable.assignment_overrides.create!(unlock_at: "2022-02-01T01:00:00Z",
                                                                unlock_at_overridden: true,
                                                                lock_at: "2022-02-02T01:00:00Z",
                                                                lock_at_overridden: true)
        override2.assignment_override_students.create!(user: student_in_course.user)
        override_params = [{ id: override1.id, unlock_at: "2020-02-01T01:00:00Z" },
                           { id: override2.id, unlock_at: "2022-03-01T01:00:00Z" }]
        override_params[0][:due_at] = "2024-02-01T01:00:00Z" if support_due_at
        put :update, params: { **default_params, assignment_overrides: override_params }
        expect(response).to be_no_content
        expect(differentiable.assignment_overrides.active.count).to eq 2
        override1.reload
        expect(override1.due_at.iso8601).to eq "2024-02-01T01:00:00Z" if support_due_at
        expect(override1.due_at_overridden).to be true if support_due_at
        expect(override1.unlock_at).to eq "2020-02-01T01:00:00Z"
        expect(override1.lock_at).to be_nil
        override2.reload
        expect(override2.unlock_at.iso8601).to eq "2022-03-01T01:00:00Z"
        expect(override2.unlock_at_overridden).to be true
        expect(override2.lock_at).to be_nil
        expect(override2.lock_at_overridden).to be false
      end

      it "updates multiple overrides" do
        override1 = differentiable.assignment_overrides.create!(course_section: @course.default_section,
                                                                unlock_at: "2020-04-01T00:00:00Z",
                                                                unlock_at_overridden: true)
        student1 = student_in_course(name: "Student 1").user
        student2 = student_in_course(name: "Student 2").user
        section2 = @course.course_sections.create!(name: "Section 2")
        override2 = differentiable.assignment_overrides.create!(lock_at: "2022-02-02T01:00:00Z", lock_at_overridden: true)
        override2.assignment_override_students.create!(user: student1)
        put :update, params: { **default_params,
          assignment_overrides: [{ course_section_id: section2.id, unlock_at: "2024-01-01T01:00:00Z" },
                                 { id: override2.id, student_ids: [student2.id] }] }
        expect(response).to be_no_content
        expect(differentiable.assignment_overrides.active.count).to eq 2
        expect(override1.reload).to be_deleted
        override2.reload
        expect(override2.assignment_override_students.pluck(:user_id)).to eq [student2.id]
        expect(override2.lock_at).to be_nil
        new_override = differentiable.assignment_overrides.active.last
        expect(new_override.course_section.id).to eq section2.id
        expect(new_override.unlock_at.iso8601).to eq "2024-01-01T01:00:00Z"
      end

      it "doesn't duplicate module overrides on a learning object" do
        context_module = @course.context_modules.create!(name: "module")
        module1_override = context_module.assignment_overrides.create!
        context_module.content_tags.create!(content: learning_object, context: @course, tag_type: "context_module")

        override2 = differentiable.assignment_overrides.create!(unlock_at: "2022-02-01T01:00:00Z",
                                                                unlock_at_overridden: true,
                                                                lock_at: "2022-02-02T01:00:00Z",
                                                                lock_at_overridden: true)
        override2.assignment_override_students.create!(user: student_in_course.user)
        override_params = [{ id: module1_override.id },
                           { id: override2.id, unlock_at: "2022-03-01T01:00:00Z" }]
        override_params[1][:due_at] = "2024-02-01T01:00:00Z" if support_due_at
        put :update, params: { **default_params, assignment_overrides: override_params }
        expect(response).to be_no_content
        expect(differentiable.assignment_overrides.active.count).to eq 1
        expect(differentiable.all_assignment_overrides.active.count).to eq 2
        override2.reload
        expect(override2.unlock_at.iso8601).to eq "2022-03-01T01:00:00Z"
        expect(override2.unlock_at_overridden).to be true
        expect(override2.lock_at).to be_nil
        expect(override2.lock_at_overridden).to be false
      end

      it "allows creating an override for a student who's previously been deleted" do
        student_in_course
        ao = differentiable.assignment_overrides.create!
        aos = ao.assignment_override_students.create!(user: @student)
        aos.destroy
        put :update, params: { **default_params, assignment_overrides: [{ student_ids: [@student.id] }] }
        expect(response).to be_no_content
        expect(differentiable.assignment_overrides.active.count).to eq 1
        expect(differentiable.assignment_overrides.active.first.assignment_override_students.active.pluck(:user_id)).to eq [@student.id]
        expect(aos.reload).to be_deleted
      end

      it "returns bad_request if trying to create duplicate overrides" do
        put :update, params: { **default_params,
          assignment_overrides: [{ course_section_id: @course.default_section.id },
                                 { course_section_id: @course.default_section.id }] }
        expect(response.code.to_s.start_with?("4")).to be_truthy
      end

      it "returns not_found if object is deleted" do
        learning_object.destroy!
        put :update, params: { **default_params, due_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_not_found
      end

      it "returns not_found if object is not in course" do
        course_with_teacher(active_all: true, user: @teacher)
        put :update, params: { **default_params, course_id: @course.id, due_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_not_found
      end

      it "returns not_found if selective_release_ui_api is disabled" do
        Account.site_admin.disable_feature! :selective_release_ui_api
        put :update, params: { **default_params, due_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_not_found
      end

      it "returns unauthorized for students" do
        course_with_student_logged_in(course: @course)
        put :update, params: { **default_params, unlock_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_unauthorized
      end
    end

    shared_examples_for "learning objects without due dates" do
      it "returns 422 if due_at is passed in an override" do
        put :update, params: { **default_params,
          assignment_overrides: [{ course_section_id: @course.default_section.id, due_at: "2022-01-02T05:00:00Z" }] }
        expect(response).to be_unprocessable
      end

      it "ignores base due_at if provided" do
        put :update, params: { **default_params, unlock_at: "2022-01-01T05:00:00Z", due_at: "2022-01-02T05:00:00Z" }
        expect(response).to be_no_content
        expect(differentiable.reload.unlock_at.iso8601).to eq "2022-01-01T05:00:00Z"
      end
    end

    let(:default_availability_dates) do
      {
        unlock_at: "2022-01-01T00:00:00Z",
        lock_at: "2022-01-03T01:00:00Z",
        only_visible_to_overrides: true
      }
    end

    let(:default_due_date) do
      {
        due_at: "2022-01-02T00:00:00Z"
      }
    end

    context "assignments" do
      let_once(:learning_object) do
        @course.assignments.create!(
          title: "Locked Assignment",
          **default_availability_dates,
          **default_due_date
        )
      end

      let_once(:differentiable) do
        learning_object
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          assignment_id: learning_object.id
        }
      end

      include_examples "learning object updates", true

      it "returns bad_request if dates are invalid" do
        put :update, params: { **default_params, unlock_at: "2023-01-" }
        expect(response).to be_bad_request
        expect(response.body).to include "Invalid datetime for unlock_at"
      end

      it "returns unauthorized if user doesn't have manage_assignments_edit permission" do
        RoleOverride.create!(context: @course.account, permission: "manage_assignments_edit", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end
    end

    context "quizzes" do
      let_once(:learning_object) do
        @course.quizzes.create!(
          title: "Locked Assignment",
          **default_availability_dates,
          **default_due_date
        )
      end

      let_once(:differentiable) do
        learning_object
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          quiz_id: learning_object.id
        }
      end

      include_examples "learning object updates", true

      it "returns unauthorized if user doesn't have manage_assignments_edit permission" do
        RoleOverride.create!(context: @course.account, permission: "manage_assignments_edit", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end
    end

    context "graded discussions" do
      let_once(:learning_object) do
        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "graded discussion")
        assignment = discussion.assignment
        assignment.update!(**default_availability_dates, **default_due_date)
        discussion
      end

      let_once(:differentiable) do
        learning_object.assignment
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          discussion_topic_id: learning_object.id
        }
      end

      include_examples "learning object updates", true

      it "removes base dates on DiscussionTopic object if it has any" do
        learning_object.update!(**default_availability_dates)
        put :update, params: { **default_params, unlock_at: "2019-01-02T05:00:00Z" }
        expect(response).to be_no_content
        learning_object.reload
        expect(learning_object.unlock_at).to be_nil
        expect(learning_object.lock_at).to be_nil
        expect(differentiable.reload.unlock_at.iso8601).to eq "2019-01-02T05:00:00Z"
      end

      it "returns unauthorized if user doesn't have moderate_forum permission" do
        RoleOverride.create!(context: @course.account, permission: "moderate_forum", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end
    end

    context "ungraded discussions" do
      let_once(:learning_object) do
        @course.discussion_topics.create!(**default_availability_dates)
      end

      let_once(:differentiable) do
        learning_object
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          discussion_topic_id: learning_object.id
        }
      end

      include_examples "learning object updates", false
      include_examples "learning objects without due dates"

      it "removes section visibilities and changes 'is_section_specific' to false" do
        learning_object.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
          discussion_topic: learning_object,
          course_section: @course.default_section,
          workflow_state: "active"
        )
        learning_object.is_section_specific = true
        learning_object.save!

        expect(learning_object.discussion_topic_section_visibilities.count).to eq 1

        put :update, params: { **default_params, unlock_at: "2019-01-02T05:00:00Z" }
        expect(response).to be_no_content
        learning_object.reload
        expect(learning_object.is_section_specific).to be false
        expect(learning_object.discussion_topic_section_visibilities.count).to eq 0
      end

      it "returns unauthorized if user doesn't have moderate_forum permission" do
        RoleOverride.create!(context: @course.account, permission: "moderate_forum", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end
    end

    context "regular pages" do
      let_once(:learning_object) do
        @course.wiki_pages.create!(title: "My Page", **default_availability_dates)
      end

      let_once(:differentiable) do
        learning_object
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          page_id: learning_object.id
        }
      end

      include_examples "learning object updates", false
      include_examples "learning objects without due dates"

      it "creates an assignment if noop override is included and conditional release is enabled" do
        @course.conditional_release = true
        @course.save!
        expect(learning_object.assignment).to be_nil
        put :update, params: { **default_params, only_visible_to_overrides: true, assignment_overrides: [{ noop_id: 1 }] }
        expect(response).to be_no_content
        learning_object.reload
        expect(learning_object.assignment).to be_present
        expect(learning_object.assignment.title).to eq "My Page"
        expect(learning_object.assignment.only_visible_to_overrides).to be true
        expect(learning_object.assignment.assignment_overrides.active.pluck(:set_type)).to eq ["Noop"]
      end

      it "does not create an assignment if noop override is included and conditional release is disabled" do
        expect(learning_object.assignment).to be_nil
        put :update, params: { **default_params, only_visible_to_overrides: false, assignment_overrides: [{ noop_id: 1 }] }
        expect(response).to be_no_content
        learning_object.reload
        expect(learning_object.assignment).to be_nil
        expect(learning_object.only_visible_to_overrides).to be false
      end

      it "does not create an assignment if noop override is not included" do
        @course.conditional_release = true
        @course.save!
        put :update, params: { **default_params, assignment_overrides: [{ course_section_id: @course.default_section.id }] }
        expect(response).to be_no_content
        expect(learning_object.reload.assignment).to be_nil
      end

      it "creates multiple overrides and sets base dates on the new assignment while adding the Noop override" do
        @course.conditional_release = true
        @course.save!
        expect(learning_object.assignment).to be_nil
        unlock_at = "2021-07-28T16:34:07Z"
        assignment_overrides = [{ course_section_id: @course.default_section.id }, { noop_id: 1 }]
        put :update, params: { **default_params, only_visible_to_overrides: false, unlock_at:, assignment_overrides: }
        expect(response).to be_no_content
        learning_object.reload
        expect(learning_object.assignment.unlock_at.iso8601).to eq unlock_at
        expect(learning_object.assignment.only_visible_to_overrides).to be false
        expect(learning_object.assignment.assignment_overrides.active.pluck(:set_type)).to contain_exactly("Noop", "CourseSection")
      end

      it "returns unauthorized if user doesn't have manage_wiki_update permission" do
        RoleOverride.create!(context: @course.account, permission: "manage_wiki_update", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end
    end

    context "pages with an assignment" do
      let_once(:learning_object) do
        page = @course.wiki_pages.create!(title: "My Page")
        page.assignment = @course.assignments.create!(
          name: "My Page",
          submission_types: ["wiki_page"],
          **default_availability_dates
        )
        page.save!
        page
      end

      let_once(:differentiable) do
        learning_object.assignment
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          page_id: learning_object.id
        }
      end

      include_examples "learning object updates", false

      it "does not remove the assignment if a noop override is removed" do
        @course.conditional_release = true
        @course.save!
        differentiable.assignment_overrides.create!(set_type: "Noop", set_id: 1)
        put :update, params: { **default_params, assignment_overrides: [] }
        expect(response).to be_no_content
        expect(learning_object.reload.assignment).to be_present
        expect(differentiable.reload.assignment_overrides.active.count).to eq 0
      end

      it "does not create a new assignment if a noop override is included" do
        @course.conditional_release = true
        @course.save!
        assignment = learning_object.assignment
        expect(assignment).to be_present
        put :update, params: { **default_params, assignment_overrides: [{ noop_id: 1 }] }
        expect(response).to be_no_content
        expect(learning_object.reload.assignment).to eq assignment
        expect(differentiable.reload.assignment_overrides.active.pluck(:set_type)).to eq ["Noop"]
      end

      it "returns unauthorized if user doesn't have manage_wiki_update permission" do
        RoleOverride.create!(context: @course.account, permission: "manage_wiki_update", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end
    end

    context "files" do
      let_once(:learning_object) do
        @course.attachments.create!(filename: "coolpdf.pdf",
                                    uploaded_data: StringIO.new("test"),
                                    **default_availability_dates)
      end

      let_once(:differentiable) do
        learning_object
      end

      let_once(:default_params) do
        {
          course_id: @course.id,
          attachment_id: learning_object.id
        }
      end

      include_examples "learning object updates", false
      include_examples "learning objects without due dates"

      it "returns unauthorized if user doesn't have manage_files_edit permission" do
        RoleOverride.create!(context: @course.account, permission: "manage_files_edit", role: teacher_role, enabled: false)
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_unauthorized
      end

      it "returns bad_request if differentiated_files is disabled" do
        Account.site_admin.disable_feature! :differentiated_files
        put :update, params: { **default_params, unlock_at: "2021-01-01T00:00:00Z" }
        expect(response).to be_bad_request
      end
    end
  end
end

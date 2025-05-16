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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
                                 }]
                               })
    end

    it "returns date details for a module" do
      context_module = @course.context_modules.create!(name: "module")
      @override.assignment_id = nil
      @override.due_at = nil
      @override.due_at_overridden = false
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
                                 }]
                               })
    end

    it "returns date details for a graded discussion with groups" do
      discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic groups")
      category = @course.group_categories.create(name: "graded topic groups")
      discussion.update!(group_category_id: category.id)
      get :show, params: { course_id: @course.id, discussion_topic_id: discussion.id }
      expect(response).to be_successful
      json = json_parse
      expect(category.id).not_to be_nil
      expect(json["group_category_id"]).to eq category.id
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
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
                                     "unassign_item" => false,
                                     "sub_assignment_due_dates" => []
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
      get :show, params: { course_id: @course.id, url_or_id: wiki_page.id }
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
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
      get :show, params: { course_id: @course.id, url_or_id: wiki_page.id }
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
                                 }]
                               })
    end

    it "returns correct date details for a checkpointed discussion" do
      @course.account.enable_feature!(:discussion_checkpoints)
      discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")

      c1_due_at = "2022-05-05T12:00:00Z"
      c1_unlock_at = "2022-05-04T12:00:00Z"
      c1_lock_at = "2022-05-08T12:00:00Z"
      c1_override_due_at = "2022-04-06T12:00:00Z"
      c1_override_unlock_at = "2022-04-05T12:00:00Z"
      c1_override_lock_at = "2022-04-07T12:00:00Z"

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [
          {
            type: "everyone",
            due_at: c1_due_at,
            unlock_at: c1_unlock_at,
            lock_at: c1_lock_at,
          },
          {
            type: "override",
            set_type: "CourseSection",
            set_id: @course.default_section.id,
            due_at: c1_override_due_at,
            unlock_at: c1_override_unlock_at,
            lock_at: c1_override_lock_at
          },
        ],
        points_possible: 5
      )

      c2_due_at = "2022-05-06T12:00:00Z"
      c2_unlock_at = "2022-05-05T12:00:00Z"
      c2_lock_at = "2022-05-07T12:00:00Z"
      c2_override_due_at = "2022-04-06T12:00:00Z"
      c2_override_unlock_at = "2022-04-05T12:00:00Z"
      c2_override_lock_at = "2022-04-07T12:00:00Z"

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [
          {
            type: "everyone",
            due_at: c2_due_at,
            unlock_at: c2_unlock_at,
            lock_at: c2_lock_at,
          },
          {
            type: "override",
            set_type: "CourseSection",
            set_id: @course.default_section.id,
            due_at: c2_override_due_at,
            unlock_at: c2_override_unlock_at,
            lock_at: c2_override_lock_at
          },
        ],
        points_possible: 10,
        replies_required: 2
      )

      # Refresh the discussion object to get the updated dates
      discussion.reload

      get :show, params: { course_id: @course.id, discussion_topic_id: discussion.id }
      expect(response).to be_successful
      json = json_parse

      # Test base discussion attributes
      expect(json).to include(
        "id" => discussion.id,
        "due_at" => nil,
        "unlock_at" => c2_unlock_at,  # Should be synced to the latest unlock_at
        "lock_at" => c2_lock_at,      # Should be synced to the latest lock_at
        "only_visible_to_overrides" => false,
        "visible_to_everyone" => true,
        "group_category_id" => nil,
        "graded" => true
      )

      # Test checkpoints
      expect(json["checkpoints"].length).to eq(2)

      # Find checkpoints by tag
      reply_to_topic = json["checkpoints"].find { |cp| cp["tag"] == CheckpointLabels::REPLY_TO_TOPIC }
      reply_to_entry = json["checkpoints"].find { |cp| cp["tag"] == CheckpointLabels::REPLY_TO_ENTRY }

      # Test reply_to_topic checkpoint
      expect(reply_to_topic).to include(
        "tag" => CheckpointLabels::REPLY_TO_TOPIC,
        "due_at" => c1_due_at,
        "unlock_at" => c2_unlock_at,  # Should be synced to the latest unlock_at
        "lock_at" => c2_lock_at,      # Should be synced to the latest lock_at
        "only_visible_to_overrides" => false,
        "points_possible" => 5.0
      )

      expect(reply_to_topic["overrides"][0]).to include(
        "title" => "Unnamed Course",
        "due_at" => c1_override_due_at,
        "all_day" => false,
        "all_day_date" => c1_override_due_at.to_date.to_s,
        "unlock_at" => c1_override_unlock_at,
        "lock_at" => c1_override_lock_at,
        "course_section_id" => @course.default_section.id
      )

      # Test reply_to_entry checkpoint
      expect(reply_to_entry).to include(
        "tag" => CheckpointLabels::REPLY_TO_ENTRY,
        "due_at" => c2_due_at,
        "unlock_at" => c2_unlock_at,
        "lock_at" => c2_lock_at,
        "only_visible_to_overrides" => false,
        "points_possible" => 10.0
      )

      expect(reply_to_entry["overrides"][0]).to include(
        "title" => "Unnamed Course",
        "due_at" => c2_override_due_at,
        "all_day" => false,
        "all_day_date" => c2_override_due_at.to_date.to_s,
        "unlock_at" => c2_override_unlock_at,
        "lock_at" => c2_override_lock_at,
        "course_section_id" => @course.default_section.id
      )
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
                                   "unassign_item" => false,
                                   "sub_assignment_due_dates" => []
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
                                   "unassign_item" => true,
                                   "sub_assignment_due_dates" => []
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

    it "paginates overrides for wiki pages using page id" do
      wiki_page = @course.wiki_pages.create!(title: "My Page")
      override1 = wiki_page.assignment_overrides.create!
      override2 = wiki_page.assignment_overrides.create!

      get :show, params: { course_id: @course.id, url_or_id: wiki_page.id, per_page: 1 }

      expect(response).to be_successful
      json = json_parse
      expect(json["id"]).to eq wiki_page.id
      expect(json["overrides"].length).to eq 1
      expect(json["overrides"][0]["id"]).to eq override1.id

      get :show, params: { course_id: @course.id, url_or_id: wiki_page.id, per_page: 1, page: 2 }

      expect(response).to be_successful
      json = json_parse
      expect(json["id"]).to eq wiki_page.id
      expect(json["overrides"].length).to eq 1
      expect(json["overrides"][0]["id"]).to eq override2.id
    end

    it "paginates overrides for wiki pages using page url" do
      wiki_page = @course.wiki_pages.create!(title: "My Page")
      override1 = wiki_page.assignment_overrides.create!
      override2 = wiki_page.assignment_overrides.create!

      get :show, params: { course_id: @course.id, url_or_id: wiki_page.url, per_page: 1 }

      expect(response).to be_successful
      json = json_parse
      expect(json["id"]).to eq wiki_page.id
      expect(json["overrides"].length).to eq 1
      expect(json["overrides"][0]["id"]).to eq override1.id

      get :show, params: { course_id: @course.id, url_or_id: wiki_page.url, per_page: 1, page: 2 }

      expect(response).to be_successful
      json = json_parse
      expect(json["id"]).to eq wiki_page.id
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

    it "returns bad_request if attempting to get a file's details and differentiated_files is disabled" do
      Account.site_admin.disable_feature! :differentiated_files
      attachment = @course.attachments.create!(filename: "coolpdf.pdf", uploaded_data: StringIO.new("test"))
      get :show, params: { course_id: @course.id, attachment_id: attachment.id }
      expect(response).to be_bad_request
    end

    context "with non-collaborative groups overrides" do
      before do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.settings = { allow_assign_to_differentiation_tags: { value: true } }
        @course.account.save

        @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
        @group_category.create_groups(2)
        @group = @group_category.groups.first
        @group.add_user(@student, "accepted")
      end

      def returns_non_collaborative_field_for_group_overrides(hide_group_name: false)
        due_at = 7.days.from_now
        # to properly override a due date, due_at_overridden needs to be true
        override2 = @assignment.assignment_overrides.create!(set: @group, due_at_overridden: true, due_at:)

        get :show, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(response).to be_successful
        expected_response = {
          "id" => @assignment.id,
          "due_at" => "2022-01-02T00:00:00Z",
          "unlock_at" => "2022-01-01T00:00:00Z",
          "lock_at" => "2022-01-03T01:00:00Z",
          "only_visible_to_overrides" => true,
          "group_category_id" => nil,
          "graded" => true,
          "visible_to_everyone" => false,
          "overrides" => [
            {
              "id" => @override.id,
              "assignment_id" => @assignment.id,
              "title" => "Unnamed Course",
              "course_section_id" => @course.default_section.id,
              "due_at" => "2022-02-01T01:00:00Z",
              "all_day" => false,
              "all_day_date" => "2022-02-01",
              "unassign_item" => false,
              "sub_assignment_due_dates" => []
            },
            {
              "id" => override2.id,
              "assignment_id" => @assignment.id,
              "title" => "Non-Collaborative Group 1",
              "due_at" => due_at.iso8601,
              "all_day" => false,
              "all_day_date" => due_at.to_date.to_s,
              "unassign_item" => false,
              "group_id" => @group.id,
              "non_collaborative" => true,
              "group_category_id" => @group.group_category.id,
              "sub_assignment_due_dates" => []
            }
          ]
        }

        if hide_group_name
          expected_response["overrides"][1].delete("title")
        end

        expect(json_parse).to eq(expected_response)
      end

      it "returns the non_collaborative field for group overrides" do
        returns_non_collaborative_field_for_group_overrides
      end

      context "as a TA" do
        before do
          @ta = user_factory(active_all: true)
          @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active")

          user_session(@ta)
        end

        it "returns the non_collaborative field for group overrides" do
          # TA should not see the group name for non-collaborative groups
          returns_non_collaborative_field_for_group_overrides(hide_group_name: true)
        end
      end
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

    context "checkpointed discussions in a context module with overrides" do
      before do
        @course.account.enable_feature! :discussion_checkpoints
        course_with_student(course: @course)

        @checkpoint_due_at = "2022-05-05T12:00:00Z"

        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        context_module = @course.context_modules.create!(name: "module")
        override = context_module.assignment_overrides.create!(set_type: "ADHOC")
        override.assignment_override_students.create!(user: @student)
        context_module.content_tags.create!(content: @discussion, context: @course, tag_type: "context_module")

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            {
              type: "override",
              due_at: @checkpoint_due_at,
              unlock_at: nil,
              lock_at: nil,
              set_type: "Course"
            },
          ],
          points_possible: 5
        )

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            {
              type: "override",
              due_at: @checkpoint_due_at,
              unlock_at: nil,
              lock_at: nil,
              set_type: "Course"
            },
          ],
          points_possible: 15,
          replies_required: 3
        )

        @discussion = discussion.reload

        @default_params = {
          course_id: @course.id,
          discussion_topic_id: @discussion.id
        }
      end

      it "returns course override dates as checkpoint due_at dates" do
        get :show, params: { course_id: @course.id, assignment_id: @discussion.assignment.id }

        expect(response).to be_successful
        expect(json_parse["checkpoints"].first["due_at"]).to eq(@checkpoint_due_at)
        expect(json_parse["checkpoints"].second["due_at"]).to eq(@checkpoint_due_at)
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

      it "allows removing differentiation tag overrides when account setting is disabled" do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.settings = { allow_assign_to_differentiation_tags: { value: true } }
        @course.account.save

        @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
        @group_category.create_groups(2)
        @group = @group_category.groups.first
        @group.add_user(@student, "accepted")

        differentiable.assignment_overrides.create!(set_type: "Group", set: @group)
        expect(differentiable.assignment_overrides.active.count).to eq 1

        # disable account setting
        @course.account.settings = { allow_assign_to_differentiation_tags: { value: false } }
        @course.account.save

        put :update, params: { **default_params, assignment_overrides: [] }
        expect(response).to be_no_content
        expect(differentiable.assignment_overrides.active.count).to eq 0
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

      context "with non-collaborative groups overrides" do
        before do
          @course.account.enable_feature!(:assign_to_differentiation_tags)
          @course.account.settings = { allow_assign_to_differentiation_tags: { value: true } }
          @course.account.save

          @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
          @group_category.create_groups(2)
          @group = @group_category.groups.first
          @group.add_user(@student, "accepted")
        end

        def adds_an_override_for_a_group
          put :update, params: { **default_params, assignment_overrides: [{ group_id: @group.id, due_at: 7.days.from_now.to_json }] }

          expect(response).to be_no_content
          expect(differentiable.assignment_overrides.active.count).to eq 1

          assignment_override = differentiable.assignment_overrides.active.first

          expect(assignment_override.set_id).to eq @group.id
          expect(assignment_override.set.non_collaborative?).to be true
        end

        it "adds an override for a group" do
          adds_an_override_for_a_group
        end

        it "throws error if setting is disabled" do
          @course.account.settings = { allow_assign_to_differentiation_tags: { value: false } }
          @course.account.save

          put :update, params: { **default_params, assignment_overrides: [{ group_id: @group.id, due_at: 7.days.from_now.to_json }] }
          expect(response).to be_bad_request
        end

        it "allows assigning differentiation tag group to group assignment" do
          collab_group_cat = @course.group_categories.create!(name: "Collaborative Group", non_collaborative: false)
          collab_group_cat.create_groups(1)
          collab_group = collab_group_cat.groups.first
          collab_group.add_user(@student, "accepted")

          group_assignment = @course.assignments.create!(
            title: "Group Assignment",
            **default_availability_dates,
            **default_due_date,
            group_category_id: collab_group_cat.id
          )

          { course_id: @course.id,
            assignment_id: group_assignment.id }

          adds_an_override_for_a_group
        end

        it "successful when removing differentiation tag overrides and account setting is disabled" do
          # Add diff tag override
          put :update, params: { **default_params, assignment_overrides: [{ group_id: @group.id, due_at: 7.days.from_now.to_json }] }
          expect(response).to be_no_content
          expect(differentiable.assignment_overrides.active.count).to eq 1

          @course.account.settings = { allow_assign_to_differentiation_tags: { value: false } }
          @course.account.save

          # Remove diff tag override
          put :update, params: { **default_params, assignment_overrides: [] }
          expect(response).to be_no_content
          expect(differentiable.assignment_overrides.active.count).to eq 0
        end

        context "works with TAs" do
          before do
            @ta = user_factory(active_all: true)
            @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active")

            user_session(@ta)
          end

          it "adds an override for a group" do
            adds_an_override_for_a_group
          end
        end
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

    context "checkpointed discussions" do
      before do
        @course.account.enable_feature! :discussion_checkpoints

        @default_override_due_at = "2022-01-02T05:00:00Z"
        @default_override_unlock_at = "2022-01-01T00:00:00Z"
        @default_override_lock_at = "2022-01-03T01:00:00Z"

        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            {
              type: "everyone",
              due_at: default_due_date[:due_at],
              unlock_at: default_availability_dates[:unlock_at],
              lock_at: default_availability_dates[:lock_at],
            },
            {
              type: "override",
              set_type: "CourseSection",
              set_id: @course.default_section.id,
              due_at: @default_override_due_at,
              unlock_at: @default_override_unlock_at,
              lock_at: @default_override_lock_at
            },
          ],
          points_possible: 5
        )

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            {
              type: "everyone",
              due_at: default_due_date[:due_at],
              unlock_at: default_availability_dates[:unlock_at],
              lock_at: default_availability_dates[:lock_at],
            },
            {
              type: "override",
              set_type: "CourseSection",
              set_id: @course.default_section.id,
              due_at: @default_override_due_at,
              unlock_at: @default_override_unlock_at,
              lock_at: @default_override_lock_at
            },
          ],
          points_possible: 10,
          replies_required: 2
        )
        @discussion = discussion.reload

        @default_params = {
          course_id: @course.id,
          discussion_topic_id: @discussion.id
        }
      end

      it "updates overrides" do
        override_params = [{ id: @discussion.assignment.assignment_overrides.first.id, unlock_at: "2020-02-01T01:00:00Z" }]
        override_params[0][:reply_to_topic_due_at] = "2024-02-02T01:00:00Z"
        override_params[0][:required_replies_due_at] = "2024-02-03T01:00:00Z"

        put :update, params: { **@default_params, assignment_overrides: override_params }
        expect(response).to be_no_content

        # Verify that the everyone override did not change
        expect(@discussion.assignment.sub_assignments.first.due_at).to eq default_due_date[:due_at]
        expect(@discussion.assignment.sub_assignments.first.unlock_at).to eq default_availability_dates[:unlock_at]
        expect(@discussion.assignment.sub_assignments.first.lock_at).to eq default_availability_dates[:lock_at]

        # Verify that the parent_override dates were updated correctly
        expect(@discussion.assignment.assignment_overrides.active.count).to eq 1
        expect(@discussion.assignment.assignment_overrides.first.unlock_at).to eq "2020-02-01T01:00:00Z"

        # Get the correct sub_assignments
        reply_to_topic = @discussion.assignment.sub_assignments.find do |sub_assignment|
          sub_assignment.sub_assignment_tag == CheckpointLabels::REPLY_TO_TOPIC
        end
        reply_to_entry = @discussion.assignment.sub_assignments.find do |sub_assignment|
          sub_assignment.sub_assignment_tag == CheckpointLabels::REPLY_TO_ENTRY
        end

        # Verify that the sub_assignment overrides were updated correctly
        expect(reply_to_topic.assignment_overrides.active.count).to eq 1
        expect(reply_to_topic.assignment_overrides.first.due_at).to eq "2024-02-02T01:00:00Z"
        expect(reply_to_topic.assignment_overrides.first.unlock_at).to eq "2020-02-01T01:00:00Z"

        expect(reply_to_entry.assignment_overrides.active.count).to eq 1
        expect(reply_to_entry.assignment_overrides.first.due_at).to eq "2024-02-03T01:00:00Z"
        expect(reply_to_entry.assignment_overrides.first.unlock_at).to eq "2020-02-01T01:00:00Z"
      end

      it "updates base dates" do
        request_params = {
          **@default_params,
          reply_to_topic_due_at: "2023-01-02T05:00:00Z",
          required_replies_due_at: "2023-01-02T05:00:00Z",
          unlock_at: "2023-01-01T00:00:00Z",
          lock_at: "2023-01-07T08:00:00Z",
          only_visible_to_overrides: false
        }

        put :update, params: request_params
        expect(response).to be_no_content
        @discussion.reload
        expect(@discussion.assignment.unlock_at.iso8601).to eq "2023-01-01T00:00:00Z"
        expect(@discussion.assignment.lock_at.iso8601).to eq "2023-01-07T08:00:00Z"
        expect(@discussion.assignment.only_visible_to_overrides).to be false

        expect(@discussion.assignment.sub_assignments.first.due_at.iso8601).to eq request_params[:reply_to_topic_due_at]
        expect(@discussion.assignment.sub_assignments.second.due_at.iso8601).to eq request_params[:required_replies_due_at]
      end

      it "does not touch other object attributes" do
        original_title = @discussion.title
        put :update, params: { **@default_params, reply_to_topic_due_at: "2022-01-02T01:00:00Z" }
        expect(response).to be_no_content
        expect(@discussion.reload.title).to eq original_title
      end

      it "works if only some arguments are passed" do
        put :update, params: { **@default_params, unlock_at: "2020-01-01T00:00:00Z" }
        expect(response).to be_no_content
        updated_discussion_assigment = @discussion.assignment.reload
        expect(updated_discussion_assigment.unlock_at.iso8601).to eq "2020-01-01T00:00:00Z"
        expect(updated_discussion_assigment.lock_at.iso8601).to eq "2022-01-03T01:00:00Z"
      end

      it "removes overrides" do
        expect(@discussion.assignment.assignment_overrides.active.count).to eq 1
        put :update, params: { **@default_params, assignment_overrides: [] }
        expect(response).to be_no_content
        @discussion.reload
        expect(@discussion.assignment.assignment_overrides.active.count).to eq 0
      end

      it "updates multiple overrides" do
        student2 = student_in_course(name: "Student 2").user
        section2 = @course.course_sections.create!(name: "Section 2")

        put :update, params: {
          **@default_params,
          assignment_overrides: [
            { course_section_id: section2.id, unlock_at: "2024-01-01T01:00:00Z", reply_to_topic_due_at: "2024-01-15T01:00:00Z", required_replies_due_at: "2024-01-20T01:00:00Z" },
            { student_ids: [student2.id], unlock_at: "2024-02-01T01:00:00Z", reply_to_topic_due_at: "2024-02-15T01:00:00Z", required_replies_due_at: "2024-02-20T01:00:00Z" }
          ]
        }

        expect(response).to be_no_content
        @discussion.reload

        # Check the number of active overrides
        expect(@discussion.assignment.assignment_overrides.active.count).to eq 2

        # Find sub-assignments
        reply_to_topic = @discussion.assignment.sub_assignments.find { |sa| sa.sub_assignment_tag == CheckpointLabels::REPLY_TO_TOPIC }
        reply_to_entry = @discussion.assignment.sub_assignments.find { |sa| sa.sub_assignment_tag == CheckpointLabels::REPLY_TO_ENTRY }

        # Check the number of active overrides for each sub-assignment
        expect(reply_to_topic.assignment_overrides.active.count).to eq 2
        expect(reply_to_entry.assignment_overrides.active.count).to eq 2

        # Course Section Override checks
        course_section_parent_override = @discussion.assignment.assignment_overrides.active.find { |ao| ao.set_type == "CourseSection" }
        course_section_reply_to_topic_override = reply_to_topic.assignment_overrides.active.find { |ao| ao.set_type == "CourseSection" }
        course_section_reply_to_entry_override = reply_to_entry.assignment_overrides.active.find { |ao| ao.set_type == "CourseSection" }

        expect(course_section_parent_override.set).to eq section2
        expect(course_section_parent_override.unlock_at.iso8601).to eq "2024-01-01T01:00:00Z"
        expect(course_section_parent_override.due_at).to be_nil
        expect(course_section_parent_override.lock_at).to be_nil

        expect(course_section_reply_to_topic_override.set).to eq section2
        expect(course_section_reply_to_topic_override.unlock_at.iso8601).to eq "2024-01-01T01:00:00Z"
        expect(course_section_reply_to_topic_override.due_at.iso8601).to eq "2024-01-15T01:00:00Z"
        expect(course_section_reply_to_topic_override.lock_at).to be_nil

        expect(course_section_reply_to_entry_override.set).to eq section2
        expect(course_section_reply_to_entry_override.unlock_at.iso8601).to eq "2024-01-01T01:00:00Z"
        expect(course_section_reply_to_entry_override.due_at.iso8601).to eq "2024-01-20T01:00:00Z"
        expect(course_section_reply_to_entry_override.lock_at).to be_nil

        # Student Override checks
        student_parent_override = @discussion.assignment.assignment_overrides.active.find { |ao| ao.set_type == "ADHOC" }
        student_reply_to_topic_override = reply_to_topic.assignment_overrides.active.find { |ao| ao.set_type == "ADHOC" }
        student_reply_to_entry_override = reply_to_entry.assignment_overrides.active.find { |ao| ao.set_type == "ADHOC" }

        expect(student_parent_override.set).to eq [student2]
        expect(student_parent_override.unlock_at.iso8601).to eq "2024-02-01T01:00:00Z"
        expect(student_parent_override.due_at).to be_nil
        expect(student_parent_override.lock_at).to be_nil

        expect(student_reply_to_topic_override.set).to eq [student2]
        expect(student_reply_to_topic_override.unlock_at.iso8601).to eq "2024-02-01T01:00:00Z"
        expect(student_reply_to_topic_override.due_at.iso8601).to eq "2024-02-15T01:00:00Z"
        expect(student_reply_to_topic_override.lock_at).to be_nil

        expect(student_reply_to_entry_override.set).to eq [student2]
        expect(student_reply_to_entry_override.unlock_at.iso8601).to eq "2024-02-01T01:00:00Z"
        expect(student_reply_to_entry_override.due_at.iso8601).to eq "2024-02-20T01:00:00Z"
        expect(student_reply_to_entry_override.lock_at).to be_nil
      end

      it "returns not_found if discussion is deleted" do
        @discussion.destroy!
        put :update, params: { **@default_params, reply_to_topic_due_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_not_found
      end

      it "returns not_found if discussion is not in course" do
        course_with_teacher(active_all: true, user: @teacher)
        put :update, params: { **@default_params, course_id: @course.id, reply_to_topic_due_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_not_found
      end

      it "returns unauthorized for students" do
        course_with_student_logged_in(course: @course)
        put :update, params: { **@default_params, unlock_at: "2020-03-02T05:59:00Z" }
        expect(response).to be_unauthorized
      end

      it "does not alter discussion.reply_to_entry_required_count" do
        reply_to_entry_required_count = @discussion.reply_to_entry_required_count
        expect do
          put :update, params: { **@default_params }
          expect(response).to be_no_content
        end.not_to change { @discussion.reply_to_entry_required_count }.from(reply_to_entry_required_count)
      end
    end

    context "checkpointed discussions with dates in future" do
      before do
        @course.account.enable_feature! :discussion_checkpoints

        @student2 = student_in_course(name: "Student 2").user

        @reply_to_topic_points = 5
        @reply_to_entry_points = 15

        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        @reply_to_topic = Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "ADHOC", student_ids: [@student2.id] }],
          points_possible: @reply_to_topic_points
        )

        @reply_to_entry = Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "override", set_type: "ADHOC", student_ids: [@student2.id] }],
          points_possible: @reply_to_entry_points,
          replies_required: 3
        )
        @discussion = discussion.reload

        @default_params = {
          course_id: @course.id,
          discussion_topic_id: @discussion.id
        }
      end

      it "creates a override for a prior date and verify that missing is set correctly" do
        missing_submission_deduction = 10.0
        @course.create_late_policy(
          missing_submission_deduction_enabled: true,
          missing_submission_deduction:
        )

        parent_assignment_override = @discussion.assignment.assignment_overrides.active.first
        request_params = {
          **@default_params,
          only_visible_to_overrides: true
        }

        put :update, params: {
          **request_params,
          assignment_overrides: [
            { id: parent_assignment_override.id, due_at: nil, lock_at: nil, reply_to_topic_due_at: 7.days.ago, required_replies_due_at: 14.days.ago, student_ids: [@student2.id], unassign_item: false, unlock_at: nil }
          ]
        }

        @reply_to_topic.reload
        @reply_to_entry.reload

        parent_assignment = @discussion.assignment
        student2_parent_submission = parent_assignment.submission_for_student(@student2)
        student2_reply_to_topic_submission = @reply_to_topic.submission_for_student(@student2)
        student2_reply_to_entry_submission = @reply_to_entry.submission_for_student(@student2)

        expect(student2_reply_to_topic_submission.missing?).to be true
        expect(student2_reply_to_entry_submission.missing?).to be true
        expect(student2_parent_submission.missing?).to be true

        expected_reply_to_topic_score = @reply_to_topic_points.to_f * ((100 - missing_submission_deduction.to_f) / 100)
        expected_reply_to_entry_score = @reply_to_entry_points.to_f * ((100 - missing_submission_deduction.to_f) / 100)
        expected_parent_score = expected_reply_to_topic_score + expected_reply_to_entry_score

        expect(student2_reply_to_topic_submission.score).to eq expected_reply_to_topic_score
        expect(student2_reply_to_entry_submission.score).to eq expected_reply_to_entry_score

        expect(student2_parent_submission.score).to eq expected_parent_score
      end
    end

    context "basic checkpointed discussions w/all dates" do
      before do
        @course.account.enable_feature! :discussion_checkpoints

        @reply_to_topic_due_at = 7.days.from_now
        @reply_to_entry_due_at = 14.days.from_now
        @unlock_at = 5.days.from_now
        @lock_at = 16.days.from_now

        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            {
              type: "everyone",
              due_at: @reply_to_topic_due_at,
              unlock_at: @unlock_at,
              lock_at: @lock_at,
            },
          ],
          points_possible: 5
        )

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            {
              type: "everyone",
              due_at: @reply_to_entry_due_at,
              unlock_at: @unlock_at,
              lock_at: @lock_at,
            },
          ],
          points_possible: 15,
          replies_required: 3
        )

        @discussion = discussion.reload

        @default_params = {
          course_id: @course.id,
          discussion_topic_id: @discussion.id
        }
      end

      it "clearing all dates updates as expected" do
        put :update, params: { **@default_params, unlock_at: nil, lock_at: nil, reply_to_topic_due_at: nil, required_replies_due_at: nil }
        expect(response).to be_no_content

        @discussion.reload

        reply_to_topic_checkpoint = @discussion.assignment.sub_assignments.find { |sa| sa.sub_assignment_tag == CheckpointLabels::REPLY_TO_TOPIC }
        reply_to_entry_checkpoint = @discussion.assignment.sub_assignments.find { |sa| sa.sub_assignment_tag == CheckpointLabels::REPLY_TO_ENTRY }

        expect(reply_to_topic_checkpoint.due_at).to be_nil
        expect(reply_to_topic_checkpoint.unlock_at).to be_nil
        expect(reply_to_topic_checkpoint.lock_at).to be_nil
        expect(reply_to_topic_checkpoint.only_visible_to_overrides).to be false

        expect(reply_to_entry_checkpoint.due_at).to be_nil
        expect(reply_to_entry_checkpoint.unlock_at).to be_nil
        expect(reply_to_entry_checkpoint.lock_at).to be_nil
        expect(reply_to_entry_checkpoint.only_visible_to_overrides).to be false
      end

      it "updates checkpoint due_at dates with course override dates when in a module with overrides" do
        course_with_student(course: @course)
        context_module = @course.context_modules.create!(name: "module")
        override = context_module.assignment_overrides.create!(set_type: "ADHOC")
        override.assignment_override_students.create!(user: @student)
        context_module.content_tags.create!(content: @discussion, context: @course, tag_type: "context_module")

        put :update, params: {
          **@default_params,
          only_visible_to_overrides: true,
          assignment_overrides: [
            due_at: nil,
            reply_to_topic_due_at: @reply_to_topic_due_at,
            required_replies_due_at: @reply_to_entry_due_at,
            unlock_at: @unlock_at,
            lock_at: @lock_at,
            course_id: "everyone",
            unassign_item: false
          ]
        }

        expect(response).to be_successful
        expect(@discussion.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC).due_at).to be_within(1.second).of(@reply_to_topic_due_at)
        expect(@discussion.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY).due_at).to be_within(1.second).of(@reply_to_entry_due_at)
      end
    end

    context "checkpointed discussions in a context module" do
      before do
        @course.account.enable_feature! :discussion_checkpoints
        course_with_student(course: @course)
        @context_module = @course.context_modules.create!(name: "module")

        @reply_to_topic_due_at = 7.days.from_now
        @reply_to_entry_due_at = 14.days.from_now
        @unlock_at = 5.days.from_now
        @lock_at = 16.days.from_now

        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        @context_module.content_tags.create!(content: discussion, context: @course, tag_type: "context_module")

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            {
              type: "override",
              due_at: @checkpoint_due_at,
              unlock_at: nil,
              lock_at: nil,
              set_type: "Course"
            },
          ],
          points_possible: 5
        )

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            {
              type: "override",
              due_at: @checkpoint_due_at,
              unlock_at: nil,
              lock_at: nil,
              set_type: "Course"
            },
          ],
          points_possible: 15,
          replies_required: 3
        )

        @discussion = discussion.reload

        @default_params = {
          course_id: @course.id,
          discussion_topic_id: @discussion.id
        }
      end

      context "with student overrides" do
        before do
          @module_override = @context_module.assignment_overrides.create!(set_type: "ADHOC")
          @module_override.assignment_override_students.create!(user: @student)
        end

        it "handles delete course override" do
          override = @discussion.assignment.assignment_overrides.first

          put :update, params: {
            **@default_params,
            only_visible_to_overrides: true,
            assignment_overrides: [{
              due_at: nil,
              id: @module_override.id,
              lock_at: nil,
              reply_to_topic_due_at: nil,
              required_replies_due_at: nil,
              student_ids: [@student.id.to_s],
              unassign_item: false,
              unlock_at: nil,
            }]
          }

          expect(response).to be_successful
          expect(override.reload).to be_deleted
        end

        it "handles unassigning module override" do
          assignment = @discussion.assignment
          override = @discussion.assignment.assignment_overrides.first

          put :update, params: {
            **@default_params,
            only_visible_to_overrides: true,
            assignment_overrides: [{
              course_id: "everyone",
              due_at: nil,
              id: override.id,
              lock_at: assignment.lock_at,
              reply_to_topic_due_at: assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC).due_at,
              required_replies_due_at: assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY).due_at,
              unassign_item: false,
              unlock_at: assignment.unlock_at
            },
                                   {
                                     due_at: nil,
                                     lock_at: nil,
                                     reply_to_topic_due_at: nil,
                                     required_replies_due_at: nil,
                                     student_ids: [@student.id.to_s],
                                     unassign_item: true,
                                     unlock_at: nil,
                                   }]
          }

          new_override = @discussion.assignment.assignment_overrides.last
          expect(response).to be_successful
          expect(new_override.unassign_item).to be(true)
        end
      end

      context "with section overrides" do
        before do
          @section1 = @course.course_sections.create!
          @module_override = @context_module.assignment_overrides.create!(set_type: "Section", set: @section1)
        end

        it "handles delete course override" do
          override = @discussion.assignment.assignment_overrides.first

          put :update, params: {
            **@default_params,
            only_visible_to_overrides: true,
            assignment_overrides: [{
              due_at: nil,
              id: @module_override.id,
              lock_at: nil,
              reply_to_topic_due_at: nil,
              required_replies_due_at: nil,
              course_section_id: @section1.id.to_s,
              unassign_item: false,
              unlock_at: nil,
            }]
          }

          expect(response).to be_successful
          expect(override.reload).to be_deleted
        end

        it "handles unassigning module override" do
          assignment = @discussion.assignment
          override = @discussion.assignment.assignment_overrides.first

          put :update, params: {
            **@default_params,
            only_visible_to_overrides: true,
            assignment_overrides: [{
              course_id: "everyone",
              due_at: nil,
              id: override.id,
              lock_at: assignment.lock_at,
              reply_to_topic_due_at: assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC).due_at,
              required_replies_due_at: assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY).due_at,
              unassign_item: false,
              unlock_at: assignment.unlock_at
            },
                                   {
                                     due_at: nil,
                                     lock_at: nil,
                                     reply_to_topic_due_at: nil,
                                     required_replies_due_at: nil,
                                     course_section_id: @section1.id.to_s,
                                     unassign_item: true,
                                     unlock_at: nil,
                                   }]
          }

          new_override = @discussion.assignment.assignment_overrides.last
          expect(response).to be_successful
          expect(new_override.unassign_item).to be(true)
        end
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
          url_or_id: learning_object.id
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

    context "PUT convert differentiation tags to ADHOC overrides" do
      before do
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!

        @diff_tag_category = @course.group_categories.create!(name: "Learning Levels", non_collaborative: true)
        @honors_tag = @course.groups.create!(name: "Honors", group_category: @diff_tag_category, non_collaborative: true)
        @standard_tag = @course.groups.create!(name: "Standard", group_category: @diff_tag_category, non_collaborative: true)

        @student1 = student_in_course(name: "Student 1").user
        @student2 = student_in_course(name: "Student 2").user
        @student3 = student_in_course(name: "Student 3").user

        # Add student 1 to honors
        @honors_tag.add_user(@student1, "accepted")

        # Add students 2 and 3 to standard
        @standard_tag.add_user(@student2, "accepted")
        @standard_tag.add_user(@student3, "accepted")
      end

      def create_diff_tag_override_for(learning_object, tag, dates)
        learning_object.assignment_overrides.create!(
          set_type: "Group",
          set: tag,
          unlock_at: dates[:unlock_at],
          due_at: dates[:due_at],
          lock_at: dates[:lock_at]
        )
      end

      def successfully_removes_diff_tag_overrides(learning_object, honors_dates, standard_dates, date_key)
        adhoc_overrides = learning_object.assignment_overrides.adhoc
        expect(adhoc_overrides.count).to eq 2

        honors_override = adhoc_overrides.find { |o| o.send(date_key) == honors_dates[date_key] }
        expect(honors_override.assignment_override_students.pluck(:user_id)).to eq [@student1.id]

        standard_override = adhoc_overrides.find { |o| o.due_at == standard_dates[:due_at] }
        expect(standard_override.assignment_override_students.pluck(:user_id)).to eq([@student2.id, @student3.id])
      end

      it "converts diff tags for Assignments" do
        assignment = @course.assignments.create!(name: "Assignment")

        honors_dates = { unlock_at: 1.day.from_now, due_at: 2.days.from_now, lock_at: 3.days.from_now }
        standard_dates = { unlock_at: 4.days.from_now, due_at: 5.days.from_now, lock_at: 6.days.from_now }

        create_diff_tag_override_for(assignment, @honors_tag, honors_dates)
        create_diff_tag_override_for(assignment, @standard_tag, standard_dates)

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, assignment_id: assignment.id }

        expect(response).to be_no_content

        successfully_removes_diff_tag_overrides(assignment, honors_dates, standard_dates, :due_at)
      end

      it "converts diff tags for Quizzes" do
        quiz = @course.quizzes.create!(title: "My Quiz")

        honors_dates = { unlock_at: 1.day.from_now, due_at: 2.days.from_now, lock_at: 3.days.from_now }
        standard_dates = { unlock_at: 4.days.from_now, due_at: 5.days.from_now, lock_at: 6.days.from_now }

        create_diff_tag_override_for(quiz, @honors_tag, honors_dates)
        create_diff_tag_override_for(quiz, @standard_tag, standard_dates)

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, quiz_id: quiz.id }

        expect(response).to be_no_content

        successfully_removes_diff_tag_overrides(quiz, honors_dates, standard_dates, :due_at)
      end

      it "converts diff tags for Discussions" do
        discussion = @course.discussion_topics.create!(title: "Discussion")

        honors_dates = { unlock_at: 1.day.from_now, lock_at: 3.days.from_now }
        standard_dates = { unlock_at: 4.days.from_now, lock_at: 6.days.from_now }

        create_diff_tag_override_for(discussion, @honors_tag, honors_dates)
        create_diff_tag_override_for(discussion, @standard_tag, standard_dates)

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, discussion_topic_id: discussion.id }

        expect(response).to be_no_content

        successfully_removes_diff_tag_overrides(discussion, honors_dates, standard_dates, :lock_at)
      end

      it "converts diff tags for Graded Discussions" do
        discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "Discussion")

        honors_dates = { unlock_at: 1.day.from_now, due_at: 2.days.from_now, lock_at: 3.days.from_now }
        standard_dates = { unlock_at: 4.days.from_now, due_at: 5.days.from_now, lock_at: 6.days.from_now }

        create_diff_tag_override_for(discussion.assignment, @honors_tag, honors_dates)
        create_diff_tag_override_for(discussion.assignment, @standard_tag, standard_dates)

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, discussion_topic_id: discussion.id }

        expect(response).to be_no_content

        successfully_removes_diff_tag_overrides(discussion.assignment, honors_dates, standard_dates, :due_at)
      end

      it "converts diff tags for Wiki Pages" do
        page = @course.wiki_pages.create!(title: "My Page")

        honors_dates = { unlock_at: 1.day.from_now, lock_at: 3.days.from_now }
        standard_dates = { unlock_at: 4.days.from_now, lock_at: 6.days.from_now }

        create_diff_tag_override_for(page, @honors_tag, honors_dates)
        create_diff_tag_override_for(page, @standard_tag, standard_dates)

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id, url_or_id: page.id }

        expect(response).to be_no_content

        successfully_removes_diff_tag_overrides(page, honors_dates, standard_dates, :lock_at)
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
          url_or_id: learning_object.id
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

    describe "create_wiki_page_mastery_path_overrides feature enabled" do
      before do
        Account.site_admin.enable_feature! :create_wiki_page_mastery_path_overrides
        @course.conditional_release = true
        @course.save!
      end

      context "pages without an assignment" do
        let_once(:learning_object) do
          page = @course.wiki_pages.create!(title: "My Page", lock_at: "2022-01-03T01:00:00Z")
          page.save!
          page
        end

        let_once(:default_params) do
          {
            course_id: @course.id,
            url_or_id: learning_object.id
          }
        end

        let_once(:differentiable) do
          learning_object
        end

        include_examples "learning object updates", false

        it "does not create assignment" do
          put :update, params: { **default_params, assignment_overrides: [{ noop_id: 1 }] }
          expect(learning_object.reload.assignment).to be_nil
        end

        it "creates assignment override and links it to wiki page" do
          put :update, params: { **default_params, assignment_overrides: [{ noop_id: 1 }] }
          expect(learning_object.assignment_overrides.active.count).to eq 1
          assignment_override = learning_object.assignment_overrides.active.first
          expect(assignment_override).to be_present
        end
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

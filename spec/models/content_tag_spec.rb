# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../lib/validates_as_url"

describe ContentTag do
  describe "::asset_workflow_state" do
    context "respond_to?(:published?)" do
      mock_asset = Class.new do
        def initialize(opts = {})
          opts = { published: true, deleted: false }.merge(opts)
          @published = opts[:published]
          @deleted = opts[:deleted]
        end

        def published?
          !!@published
        end

        def unpublished?
          !@published
        end

        def deleted?
          @deleted
        end
      end

      it "returns 'deleted' for deleted assets" do
        a = mock_asset.new(deleted: true)
        expect(ContentTag.asset_workflow_state(a)).to eq "deleted"
      end

      it "returns 'active' for published assets" do
        a = mock_asset.new(published: true)
        expect(ContentTag.asset_workflow_state(a)).to eq "active"
      end

      it "returns 'unpublished' for unpublished assets" do
        a = mock_asset.new(published: false)
        expect(ContentTag.asset_workflow_state(a)).to eq "unpublished"
      end
    end

    context "respond_to?(:workflow_state)" do
      mock_asset = Class.new do
        attr_reader :workflow_state

        def initialize(workflow_state)
          @workflow_state = workflow_state
        end
      end

      it "returns 'active' for 'active' workflow_state" do
        a = mock_asset.new("active")
        expect(ContentTag.asset_workflow_state(a)).to eq "active"
      end

      it "returns 'active' for 'available' workflow_state" do
        a = mock_asset.new("available")
        expect(ContentTag.asset_workflow_state(a)).to eq "active"
      end

      it "returns 'active' for 'published' workflow_state" do
        a = mock_asset.new("published")
        expect(ContentTag.asset_workflow_state(a)).to eq "active"
      end

      it "returns 'unpublished' for 'unpublished' workflow_state" do
        a = mock_asset.new("unpublished")
        expect(ContentTag.asset_workflow_state(a)).to eq "unpublished"
      end

      it "returns 'deleted' for 'deleted' workflow_state" do
        a = mock_asset.new("deleted")
        expect(ContentTag.asset_workflow_state(a)).to eq "deleted"
      end

      it "returns nil for other workflow_state" do
        a = mock_asset.new("terrified")
        expect(ContentTag.asset_workflow_state(a)).to eq nil
      end
    end
  end

  describe "#sync_workflow_state_to_asset?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(content_type: "Quiz")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is Quizzes::Quiz" do
      content_tag = ContentTag.new(content_type: "Quizzes::Quiz")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is Assignment" do
      content_tag = ContentTag.new(content_type: "Assignment")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is WikiPage" do
      content_tag = ContentTag.new(content_type: "WikiPage")
      expect(content_tag.sync_workflow_state_to_asset?).to be_truthy
    end

    it "true when content_type is DiscussionTopic" do
      expect(ContentTag.new(content_type: "DiscussionTopic")).to be_sync_workflow_state_to_asset
    end
  end

  describe "#content_type_quiz?" do
    it "true when content_type is Quiz" do
      content_tag = ContentTag.new(content_type: "Quiz")
      expect(content_tag.content_type_quiz?).to be_truthy
    end

    it "true when content_type is Quizzes::Quiz" do
      content_tag = ContentTag.new(content_type: "Quizzes::Quiz")
      expect(content_tag.content_type_quiz?).to be_truthy
    end

    it "false when content_type is not valid" do
      content_tag = ContentTag.new(content_type: "Assignment")
      expect(content_tag.content_type_quiz?).to be_falsey
    end
  end

  describe "#scoreable?" do
    it "true when quiz" do
      content_tag = ContentTag.new(content_type: "Quizzes::Quiz")

      expect(content_tag.scoreable?).to be_truthy
    end

    it "true when gradeable" do
      content_tag = ContentTag.new(content_type: "Assignment")

      expect(content_tag.scoreable?).to be_truthy
    end

    it "false when neither quiz nor gradeable" do
      content_tag = ContentTag.new(content_type: "DiscussionTopic")

      expect(content_tag.scoreable?).to be_falsey
    end
  end

  it "allows setting a valid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = "discussion_topic_5"
    expect(tag.content_type).to eql("DiscussionTopic")
    expect(tag.content_id).to eql(5)
  end

  it "does not allow setting an invalid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = "bad_class_41"
    expect(tag.content_type).to eql(nil)
    expect(tag.content_id).to eql(nil)

    tag.content_asset_string = "bad_class"
    expect(tag.content_type).to eql(nil)
    expect(tag.content_id).to eql(nil)

    tag.content_asset_string = "course_55"
    expect(tag.content_type).to eql(nil)
    expect(tag.content_id).to eql(nil)
  end

  it "returns content for a assignment" do
    course_factory
    assignment = course_factory.assignments.create!
    tag = ContentTag.new(content: assignment, context: @course)
    expect(tag.assignment).to eq assignment
  end

  it "returns associated assignment for a quiz" do
    course_factory
    quiz = course_factory.quizzes.create!
    tag = ContentTag.new(content: quiz, context: @course)
    expect(tag.assignment).to eq quiz.assignment
  end

  it "returns nil assignment for something else" do
    tag = ContentTag.new
    expect(tag.assignment).to be_nil
  end

  it "includes tags from a course in the for_context named scope" do
    course_factory
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(content: quiz, context: @course)
    tags = ContentTag.for_context(@course)
    expect(tags).not_to be_empty
    expect(tags.any? { |t| t.id == tag.id }).to be_truthy
  end

  it "includes tags from an account in the for_context named scope" do
    account = Account.default
    outcome = account.created_learning_outcomes.create!(title: "outcome", description: "<p>This is <b>awesome</b>.</p>")
    tag = ContentTag.create!(content: outcome, context: account)
    tags = ContentTag.for_context(account)
    expect(tags).not_to be_empty
    expect(tags.any? { |t| t.id == tag.id }).to be_truthy
  end

  it "includes tags from courses under an account in the for_context named scope" do
    course_factory
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(content: quiz, context: @course)
    tags = ContentTag.for_context(@course.account)
    expect(tags).not_to be_empty
    expect(tags.any? { |t| t.id == tag.id }).to be_truthy
  end

  it "does not rename the linked external tool if the tag is renamed" do
    course_factory
    @tool = @course.context_external_tools.create!(name: "new tool", consumer_key: "key", shared_secret: "secret", domain: "example.com", custom_fields: { "a" => "1", "b" => "2" })
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({
                              type: "context_external_tool",
                              title: "Example",
                              url: "http://www.example.com",
                              new_tab: "0"
                            })
    @tag.update_asset_name!
    @tool.reload
    expect(@tool.name).to eq "new tool"
    @tag.reload
    expect(@tag.title).to eq "Example"
  end

  it "does not rename the tag if the linked external tool is renamed" do
    course_factory
    @tool = @course.context_external_tools.create!(name: "new tool", consumer_key: "key", shared_secret: "secret", domain: "example.com", custom_fields: { "a" => "1", "b" => "2" })
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({
                              type: "context_external_tool",
                              title: "Example",
                              url: "http://www.example.com",
                              new_tab: "0"
                            })
    ContentTag.update_for(@tool)
    @tool.reload
    expect(@tool.name).to eq "new tool"
    @tag.reload
    expect(@tag.title).to eq "Example"
  end

  it "renames the linked assignment if the tag is renamed" do
    course_factory
    @assignment = @course.assignments.create!(title: "some assignment")
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({
                              type: "assignment",
                              title: "some assignment (renamed)",
                              id: @assignment.id
                            })
    @tag.update_asset_name!
    @tag.reload
    expect(@tag.title).to eq "some assignment (renamed)"
    @assignment.reload
    expect(@assignment.title).to eq "some assignment (renamed)"
  end

  it "renames the tag if the linked assignment is renamed" do
    course_factory
    @assignment = @course.assignments.create!(title: "some assignment")
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({
                              type: "assignment",
                              title: "some assignment",
                              id: @assignment.id
                            })
    @tag.reload
    expect(@tag.title).to eq "some assignment"
    @assignment.reload
    expect(@assignment.title).to eq "some assignment"
    @assignment.title = "some assignment (renamed)"
    @assignment.save!
    ContentTag.update_for(@assignment)
    @tag.reload
    expect(@tag.title).to eq "some assignment (renamed)"
    @assignment.reload
    expect(@assignment.title).to eq "some assignment (renamed)"
  end

  it "associates the tag with an external tool matching the url" do
    course_factory
    url = "http://quiz-lti.docker/lti/launch"
    tool = @course.context_external_tools.create!({
                                                    name: "tool",
                                                    consumer_key: "key",
                                                    shared_secret: "secret",
                                                    url: url
                                                  })
    assignment = @course.assignments.create!(
      title: "some assignment",
      submission_types: "external_tool",
      external_tool_tag_attributes: { url: url }
    )
    expect(assignment.external_tool_tag.content).to eq(tool)
  end

  describe ".update_for" do
    context "when updating a quiz" do
      before do
        course_factory
        @quiz = course_factory.quizzes.create!
        @module = @course.context_modules.create!(name: "module")
        @tag = @module.add_item({
                                  type: "quiz",
                                  title: "some quiz",
                                  id: @quiz.id
                                })
        @tag.reload
      end

      it "syncs workflow_state transitions publishing/unpublishing" do
        @quiz.unpublish!
        @quiz.reload

        ContentTag.update_for @quiz

        @tag.reload
        expect(@tag.workflow_state).to eq "unpublished"

        @quiz.publish!
        @quiz.reload

        ContentTag.update_for @quiz

        @tag.reload
        expect(@tag.workflow_state).to eq "active"
      end
    end
  end

  # I really want to change this to "duplicable?" but we're already returning "is_duplicate_able" in API json ಠ益ಠ
  describe "duplicate_able?" do
    before :once do
      course_factory
      @module = @course.context_modules.create!(name: "module")
    end

    it "returns true for discussion_topic tags" do
      topic = @course.discussion_topics.create! title: "topic"
      topic_tag = @module.add_item({ type: "DiscussionTopic", id: topic.id })
      expect(topic_tag).to be_duplicate_able
    end

    it "returns true for wiki_page tags" do
      page = @course.wiki_pages.create! title: "page"
      page_tag = @module.add_item({ type: "WikiPage", id: page.id })
      expect(page_tag).to be_duplicate_able
    end

    it "defers to Assignment#can_duplicate? for assignment tags" do
      assignment1 = @course.assignments.create! title: "assignment1"
      assignment2 = @course.assignments.create! title: "assignment2"
      allow_any_instantiation_of(assignment1).to receive(:can_duplicate?).and_return(true)
      allow_any_instantiation_of(assignment2).to receive(:can_duplicate?).and_return(false)
      assignment1_tag = @module.add_item({ type: "Assignment", id: assignment1.id })
      assignment2_tag = @module.add_item({ type: "Assignment", id: assignment2.id })
      expect(assignment1_tag).to be_duplicate_able
      expect(assignment2_tag).not_to be_duplicate_able
    end
  end

  it "does not attempt to update asset name attribute if it's over the db limit" do
    course_factory
    @page = @course.wiki_pages.create!(title: "some page")
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({ type: "WikiPage", title: "oh noes!" * 35, id: @page.id })

    @tag.update_asset_name!

    @page.reload
    expect(@tag.title[0, 250]).to eq @page.title[0, 250]
  end

  it "properly trims asset name for assignments" do
    course_factory
    @assign = @course.assignments.create!(title: "some assignment")
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({ type: "Assignment", title: "oh noes!" * 35, id: @assign.id })

    @tag.update_asset_name!

    @assign.reload
    expect(@tag.title[0, 250]).to eq @assign.title[0, 250]
  end

  it "publish/unpublishes the tag if the linked wiki page is published/unpublished" do
    course_factory
    @page = @course.wiki_pages.create!(title: "some page")
    @page.workflow_state = "unpublished"
    @page.save!
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({ type: "WikiPage", title: "some page", id: @page.id })
    expect(@tag.workflow_state).to eq "unpublished"

    @page.reload
    @page.workflow_state = "active"
    @page.save!
    @tag.reload
    expect(@tag.workflow_state).to eq "active"

    @page.reload
    @page.workflow_state = "unpublished"
    @page.save!
    @tag.reload
    expect(@tag.workflow_state).to eq "unpublished"
  end

  it "publish/unpublishes the linked wiki page (and its tags) if the tag is published/unpublished" do
    course_factory
    @page = @course.wiki_pages.create!(title: "some page")
    @page.workflow_state = "unpublished"
    @page.save!
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({ type: "WikiPage", title: "some page", id: @page.id })
    @tag2 = @module.add_item({ type: "WikiPage", title: "some page", id: @page.id })

    @tag.reload
    @tag.workflow_state = "active"
    @tag.save!
    @tag.update_asset_workflow_state!
    @page.reload
    expect(@page.workflow_state).to eq "active"
    @tag2.reload
    expect(@tag2.workflow_state).to eq "active"

    @tag.reload
    @tag.workflow_state = "unpublished"
    @tag.save!
    @tag.update_asset_workflow_state!
    @page.reload
    expect(@page.workflow_state).to eq "unpublished"
    @tag2.reload
    expect(@tag2.workflow_state).to eq "unpublished"
  end

  it "publishes the linked file when the tag is published" do
    file = attachment_model(locked: true)
    mod = @course.context_modules.create!(name: "module")
    tag = mod.add_item(type: "attachment", id: file.id)
    expect(tag).to be_unpublished
    tag.workflow_state = "active"
    tag.save!
    tag.update_asset_workflow_state!
    expect(file.reload).to be_published
  end

  it "publishes content via publish!" do
    assignment_model
    @assignment.unpublish!
    @module = @course.context_modules.create!
    @tag = @module.add_item(type: "Assignment", id: @assignment.id)
    @tag.workflow_state = "active"
    expect(@tag.content).to receive(:publish!).once
    @tag.save!
    @tag.update_asset_workflow_state!
  end

  it "unpublishes content via unpublish!" do
    quiz_model
    @module = @course.context_modules.create!
    @tag = @module.add_item(type: "Quiz", id: @quiz.id)
    @tag.workflow_state = "unpublished"
    expect(@tag.content).to receive(:unpublish!).once
    @tag.save!
    @tag.update_asset_workflow_state!
  end

  it "does not rename tag if linked attachment is renamed" do
    course_factory
    att = Attachment.create!(filename: "important title.txt", display_name: "important title.txt", uploaded_data: StringIO.new("It's what's on the inside of the file that doesn't matter.'"), folder: Folder.unfiled_folder(@course), context: @course)

    a_module = @course.context_modules.create!(name: "module")
    tag = a_module.add_item({ type: "attachment", title: "important title.txt", id: att.id })
    tag.update_asset_name!

    att.display_name = "no longer important.txt"
    ContentTag.update_for(att)
    tag.reload
    expect(tag.title).to eq "important title.txt"
  end

  it "does not rename attachment if linked tag is renamed" do
    course_factory
    att = Attachment.create!(filename: "important title.txt", display_name: "important title.txt", uploaded_data: StringIO.new("It's what's on the inside of the file that doesn't matter.'"), folder: Folder.unfiled_folder(@course), context: @course)

    a_module = @course.context_modules.create!(name: "module")
    tag = a_module.add_item({ type: "attachment", title: "Differently Important Title", id: att.id })
    tag.update_asset_name!

    att.reload
    expect(att.display_name).to eq "important title.txt"
  end

  include_examples "url validation tests"
  it "checks url validity" do
    quiz = course_factory.quizzes.create!
    test_url_validation(ContentTag.create!(content: quiz, context: @course))
  end

  it "touches the module after committing the save" do
    course_factory
    mod = @course.context_modules.create!
    yesterday = 1.day.ago
    ContextModule.where(id: mod).update_all(updated_at: yesterday)
    ContextModule.transaction do
      mod.add_item type: "context_module_sub_header", title: "blah"
      expect(mod.reload.updated_at.to_i).to eq yesterday.to_i
    end
    expect(mod.reload.updated_at).to be > 5.seconds.ago
  end

  it "does not touch modules that have been recently touched on save" do
    Setting.set("touch_personal_space", "10")
    course_factory
    mod = @course.context_modules.create!
    recent = Time.now
    ContextModule.where(id: mod).update_all(updated_at: recent)
    Timecop.travel(recent + 1.second) do
      ContextModule.transaction do
        mod.add_item(type: "context_module_sub_header", title: "blah")
      end
      expect(mod.reload.updated_at).to eq recent
    end
  end

  it "allows skipping touches on save" do
    course_factory
    @assignment = @course.assignments.create!(title: "some assignment")
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({
                              type: "assignment",
                              title: "some assignment (renamed)",
                              id: @assignment.id
                            })
    @tag.update_asset_name!
    @tag.reload

    yesterday = 1.day.ago
    ContextModule.where(id: @module).update_all(updated_at: yesterday)

    @tag.skip_touch = true
    @tag.save

    expect(@module.reload.updated_at.to_i).to eq yesterday.to_i
  end

  it "updates outcome root account ids after save" do
    outcome = LearningOutcome.create! title: "foo", context: nil
    course = course_factory
    expect(outcome.root_account_ids).to eq []
    ContentTag.create(tag_type: "learning_outcome_association", content: outcome, context: course)
    expect(outcome.root_account_ids).to eq [course.account.id]
  end

  describe "visible_to_students_in_course_with_da" do
    before do
      course_with_student(active_all: true)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
    end

    context "assignments" do
      before do
        @assignment = @course.assignments.create!(title: "some assignment", only_visible_to_overrides: true)
        @module = @course.context_modules.create!(name: "module")
        @tag = @module.add_item({
                                  type: "assignment",
                                  title: "some assignment",
                                  id: @assignment.id
                                })
      end

      it "returns assignments if there is visibility" do
        create_section_override_for_assignment(@assignment, { course_section: @section })
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end

      it "does not return assignments if there is no visibility" do
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).not_to include(@tag)
      end
    end

    context "discussions" do
      def attach_assignment_to_discussion
        @assignment = @course.assignments.create!(title: "some discussion assignment", only_visible_to_overrides: true)
        @assignment.submission_types = "discussion_topic"
        @assignment.save!
        @topic.assignment_id = @assignment.id
        @topic.save!
      end
      before do
        discussion_topic_model(user: @course.instructors.first, context: @course)
        @module = @course.context_modules.create!(name: "module")
        @tag = @module.add_item({
                                  type: "discussion_topic",
                                  title: "some discussion",
                                  id: @topic.id
                                })
      end

      it "returns discussions without attached assignments" do
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end

      it "returns discussions with attached assignments if there is visibility" do
        attach_assignment_to_discussion
        create_section_override_for_assignment(@assignment, { course_section: @section })
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end

      it "does not return discussions with attached assignments if there is no visibility" do
        attach_assignment_to_discussion
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).not_to include(@tag)
      end
    end

    context "quizzes" do
      before do
        @quiz = @course.quizzes.create!(only_visible_to_overrides: true)
        @module = @course.context_modules.create!(name: "module")
        @tag = @module.add_item({
                                  type: "quiz",
                                  title: "some quiz",
                                  id: @quiz.id
                                })
      end

      it "returns a quiz if there is visibility" do
        create_section_override_for_quiz(@quiz, course_section: @section)
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end

      it "does not return quiz if there is not visibility" do
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).not_to include(@tag)
      end
    end

    context "other" do
      it "properly returns wiki pages" do
        @page = @course.wiki_pages.create!(title: "some page")
        @module = @course.context_modules.create!(name: "module")
        @tag = @module.add_item({ type: "WikiPage", title: "oh noes!" * 35, id: @page.id })
        expect(ContentTag.visible_to_students_in_course_with_da(@student.id, @course.id)).to include(@tag)
      end
    end
  end

  describe "destroy" do
    before do
      course_with_teacher(active_all: true)
    end

    it "updates completion requirements on its associated ContextModule" do
      @module = @course.context_modules.create!(name: "some module")
      @assignment = @course.assignments.create!(title: "some assignment")
      @assignment2 = @course.assignments.create!(title: "some assignment2")

      @tag = @module.add_item({ id: @assignment.id, type: "assignment" })
      @tag2 = @module.add_item({ id: @assignment2.id, type: "assignment" })

      @module.completion_requirements = [{ id: @tag.id, type: "must_submit" },
                                         { id: @tag2.id, type: "must_submit" }]

      @module.save

      @tag.destroy

      expect(@module.reload.completion_requirements).to eq [{ id: @tag2.id, type: "must_submit" }]
    end

    it "runs the due date cacher when the content is Quizzes 2" do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )

      assignment = @course.assignments.create!(title: "some assignment")
      assignment.quiz_lti!
      assignment.save!

      tag = assignment.external_tool_tag

      expect(DueDateCacher).to receive(:recompute).with(assignment)

      tag.destroy!
    end

    it "does not run the due date cacher for general content" do
      tool = @course.context_external_tools.create!(
        name: "Not Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Not Quizzes 2",
        url: "http://example.com/launch"
      )

      assignment = @course.assignments.create!(
        title: "some assignment",
        submission_types: "external_tool",
        external_tool_tag_attributes: { content: tool, url: tool.url }
      )
      tag = assignment.external_tool_tag

      expect(DueDateCacher).to_not receive(:recompute).with(assignment)

      tag.destroy!
    end

    it "deletes outcome link and the associated friendly description" do
      account = Account.default
      outcome = account.created_learning_outcomes.create!(title: "outcome", description: "standard outcome description")
      description = OutcomeFriendlyDescription.create!(context: account, description: "friendly outcome description", learning_outcome: outcome)
      outcome_link = ContentTag.create!(content: outcome, context: account)
      outcome_links = ContentTag.for_context(account)
      expect(outcome_links).not_to be_empty
      expect(outcome_links.find { |link| link.id == outcome_link.id }).to_not be_nil

      outcome_link.destroy
      outcome_links = ContentTag.active.for_context(account)
      description = OutcomeFriendlyDescription.where(id: description.id).first
      expect(outcome_links.find { |link| link.id == outcome_link.id }).to be_nil
      expect(description.workflow_state).to eq("deleted")
    end
  end

  context "Quizzes 2 calls backs" do
    before do
      course_with_teacher(active_all: true)
    end

    let(:tool) do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
    end

    it "runs the due date cacher when saved if the content is Quizzes 2" do
      assignment = @course.assignments.create!(title: "some assignment", submission_types: "external_tool")

      expect(DueDateCacher).to receive(:recompute).with(assignment)

      ContentTag.create!(content: tool, url: tool.url, context: assignment)
    end

    it "does not run the due date cacher when saved if the content is Quizzes 2 but the context is a course" do
      expect(DueDateCacher).to_not receive(:recompute)

      ContentTag.create!(content: tool, url: tool.url, context: @course)
    end

    it "does not run the due date cacher when saved for general content" do
      not_quizzes_tool = @course.context_external_tools.create!(
        name: "Not Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Not Quizzes 2",
        url: "http://example.com/launch"
      )

      assignment = @course.assignments.create!(title: "some assignment", submission_types: "external_tool")

      expect(DueDateCacher).to_not receive(:recompute).with(assignment)

      ContentTag.create!(content: not_quizzes_tool, url: not_quizzes_tool.url, context: assignment)
    end
  end

  it "syncs tag published state with attachment locked state" do
    course_factory
    att = Attachment.create!(filename: "blah.txt", uploaded_data: StringIO.new("blah"),
                             folder: Folder.unfiled_folder(@course), context: @course)
    att.locked = true
    att.save!

    a_module = @course.context_modules.create!(name: "module")
    tag = a_module.add_item({ type: "attachment", id: att.id })
    expect(tag.unpublished?).to be_truthy

    att.locked = false
    att.save!
    tag.reload
    expect(tag.unpublished?).to be_falsey

    att.locked = true
    att.save!
    tag.reload
    expect(tag.unpublished?).to be_truthy
  end

  describe "after_save" do
    describe "set_root_account" do
      it "sets root_account when context is Account" do
        account = Account.default
        tag = ContentTag.create!(context: account)
        expect(tag.root_account).to eq account.root_account
      end

      it "sets root_account when context is Assignment" do
        course_factory
        assignment = @course.assignments.create!(title: "test")
        tag = ContentTag.create!(context: assignment)
        expect(tag.root_account).to eq assignment.root_account
      end

      it "sets root_account when context is Course" do
        course_factory
        tag = ContentTag.create!(context: @course)
        expect(tag.root_account).to eq @course.root_account
      end

      it "sets root_account when context is LearningOutcomeGroup" do
        account = Account.default
        group = LearningOutcomeGroup.create!(title: "test", context: account)
        tag = ContentTag.create!(context: group)
        expect(tag.root_account).to eq account.root_account
      end

      it "sets root_account when context is Quiz" do
        course_factory
        quiz = @course.quizzes.create!
        tag = ContentTag.create!(context: quiz)
        expect(tag.root_account).to eq @course.root_account
      end
    end
  end

  describe "quiz_lti" do
    it "returns true when the assignment content is quiz_lti" do
      course_factory
      assignment = new_quizzes_assignment(course: @course, title: "Some New Quiz")
      tag = ContentTag.create!(context: @course, content: assignment)
      expect(tag.quiz_lti).to be true
    end

    it "returns false if the assignment content is not quiz_lti" do
      course_factory
      assignment = course_factory.assignments.create!
      tag = ContentTag.new(context: @course, content_type: "Assignment", content: assignment)
      expect(tag.quiz_lti).to be false
    end
  end

  describe "json" do
    it "includes quiz_lti when running to_json" do
      course_factory
      tag = ContentTag.create!(context: @course)
      expect(tag.to_json).to include("quiz_lti")
    end

    it "includes quiz_lti when running as_json" do
      course_factory
      tag = ContentTag.create!(context: @course)
      expect(tag.as_json["content_tag"]).to include("quiz_lti" => false)
    end
  end

  describe "can_have_assignment scope" do
    it "returns content tags that can have assignments" do
      course_factory
      tag = ContentTag.create!(context: @course)
      expect(ContentTag.can_have_assignment).not_to include(tag)
      ["Assignment", "DiscussionTopic", "Quizzes::Quiz", "WikiPage"].each do |content_type|
        tag.update(content_type: content_type)
        expect(ContentTag.can_have_assignment).to include(tag)
      end
    end
  end

  describe "#can_have_assignment?" do
    it "true if content_type can have assignments" do
      course_factory
      tag = ContentTag.create!(context: @course)
      expect(tag.can_have_assignment?).to eq(false)
      ["Assignment", "DiscussionTopic", "Quizzes::Quiz", "WikiPage"].each do |content_type|
        tag.update(content_type: content_type)
        expect(tag.can_have_assignment?).to eq(true)
      end
    end
  end

  describe "#update_course_pace_module_items" do
    before do
      course_factory
      @course.account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      @context_module = @course.context_modules.create!
      @assignment = @course.assignments.create!
      @course_pace = @course.course_paces.create!
      @course_pace.publish
      @context_module.add_item(id: @assignment.id, type: "assignment")
      @tag = @context_module.content_tags.first
    end

    it "creates a course pace module item if a new content tag is created" do
      assignment = @course.assignments.create!
      @context_module.add_item(id: assignment.id, type: "assignment")
      tag = @context_module.content_tags.find_by(content_id: assignment.id)
      tag.update_course_pace_module_items
      expect(@course_pace.course_pace_module_items.where(module_item_id: tag.id).exists?).to eq(true)
    end

    it "deletes a CoursePaceModuleItem if a content tag is deleted" do
      @tag.update_course_pace_module_items
      expect(@course_pace.course_pace_module_items.where(module_item_id: @tag.id).exists?).to eq(true)
      @tag.destroy
      @tag.update_course_pace_module_items
      expect(@course_pace.course_pace_module_items.where(module_item_id: @tag.id).exists?).to eq(false)
    end

    it "updates all published pace plans with content tags" do
      section_pace = @course.course_paces.create!(course_section: @course.course_sections.create!)
      section_pace.publish
      assignment = @course.assignments.create!
      @context_module.add_item(id: assignment.id, type: "assignment")
      tag = @context_module.content_tags.find_by(content_id: assignment.id)
      tag.update_course_pace_module_items
      expect(@course_pace.course_pace_module_items.where(module_item_id: tag.id).exists?).to eq(true)
      expect(section_pace.course_pace_module_items.where(module_item_id: tag.id).exists?).to eq(true)
    end

    it "does not make changes if the tag_type is not 'context_module'" do
      assignment = @course.assignments.create!
      tag = ContentTag.create!(context: @course, content: assignment, tag_type: "learning_outcome")
      expect(@course_pace.course_pace_module_items.where(module_item_id: tag.id).exists?).to eq(false)
    end
  end

  describe "#trigger_publish!" do
    it "publishes the tag if it is unpublished" do
      course_factory
      tag = ContentTag.create!(context: @course, workflow_state: "unpublished")
      expect(tag.published?).to eq(false)
      tag.trigger_publish!
      expect(tag.reload.published?).to eq(true)
    end

    it "publishes the tag and the attachment content if possible" do
      course_factory
      tag = ContentTag.create!(context: @course, content: attachment_model(locked: true), workflow_state: "unpublished")
      expect(tag.published?).to eq(false)
      expect(@attachment.published?).to eq(false)
      tag.trigger_publish!
      expect(tag.reload.published?).to eq(true)
      expect(@attachment.reload.published?).to eq(true)
    end
  end

  describe "#trigger_unpublish!" do
    it "unpublishes the tag if it is published" do
      course_factory
      tag = ContentTag.create!(context: @course, workflow_state: "published")
      expect(tag.published?).to eq(true)
      tag.trigger_unpublish!
      expect(tag.reload.published?).to eq(false)
    end

    it "unpublishes the tag and locks the attachment content" do
      course_factory
      tag = ContentTag.create!(context: @course, content: attachment_model, workflow_state: "published")
      expect(tag.published?).to eq(true)
      expect(@attachment.published?).to eq(true)
      tag.trigger_unpublish!
      expect(tag.reload.published?).to eq(false)
      expect(@attachment.reload.published?).to eq(false)
    end
  end
end

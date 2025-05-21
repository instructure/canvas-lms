# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::ModuleItemType do
  let_once(:course) do
    course_with_teacher(active_all: true)
    @course
  end
  let_once(:module1) { course.context_modules.create! name: "module1" }
  let_once(:assign1) { course.assignments.create(title: "a1", workflow_state: "published") }
  let_once(:module_item1) { module1.add_item({ type: "assignment", id: assign1.id }, nil, position: 1) }

  it "works" do
    resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
    expect(resolver.resolve("_id")).to eq module_item1.id.to_s
  end

  it "gets the indent" do
    resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
    expect(resolver.resolve("indent")).to eq 0
  end

  it "gets the position" do
    resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
    expect(resolver.resolve("position")).to eq 1
  end

  context "permissions" do
    let_once(:student) { student_in_course(course:).user }

    it "requires read permission on context module" do
      module1.workflow_state = "unpublished"
      module1.save!
      resolver = GraphQLTypeTester.new(module_item1, current_user: student)
      expect(resolver.resolve("_id")).to be_nil
    end

    it "requires read permission on context" do
      other_course_student = student_in_course(course: course_factory).user
      resolver = GraphQLTypeTester.new(module_item1, current_user: other_course_student)
      expect(resolver.resolve("_id")).to be_nil
    end

    it "requires read permission on content" do
      assign1.workflow_state = "unpublished"
      assign1.save!
      resolver = GraphQLTypeTester.new(module_item1, current_user: student)
      expect(resolver.resolve("_id")).to be_nil
    end
  end

  context "Module Progressions" do
    let_once(:assign2) { course.assignments.create(title: "a2", workflow_state: "published") }
    let_once(:assign3) { course.assignments.create(title: "a3", workflow_state: "published") }
    let_once(:assign4) { course.assignments.create(title: "a4", workflow_state: "published") }
    let_once(:assign5) { course.assignments.create(title: "a5", workflow_state: "published") }
    let_once(:module_item2) { module1.add_item({ type: "assignment", id: assign2.id }, nil, position: 2) }
    let_once(:module_item3) { module1.add_item({ type: "assignment", id: assign3.id }, nil, position: 3) }
    let_once(:module_item4) { module1.add_item({ type: "assignment", id: assign4.id }, nil, position: 4) }
    let_once(:module_item5) { module1.add_item({ type: "assignment", id: assign5.id }, nil, position: 5) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item2, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item2.id.to_s
      expect(resolver.resolve("previous { _id }")).to eq module_item1.id.to_s
      expect(resolver.resolve("next { _id }")).to eq module_item3.id.to_s
    end

    it "returns null for next it does not exist" do
      resolver = GraphQLTypeTester.new(module_item5, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item5.id.to_s
      expect(resolver.resolve("next { _id }")).to be_nil
    end

    it "returns empty array for next items if there is none" do
      resolver = GraphQLTypeTester.new(module_item5, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item5.id.to_s
      expect(resolver.resolve("nextItemsConnection { nodes { _id } }")).to eq []
    end

    it "does not return an item not visible to the user" do
      course.assignments.create(title: "a6", workflow_state: "unpublished")
      module1.add_item({ type: "assignment", id: course.assignments.last.id }, nil, position: 6)
      student = student_in_course(course:).user

      resolver = GraphQLTypeTester.new(module_item5, current_user: student)
      expect(resolver.resolve("_id")).to eq module_item5.id.to_s
      expect(resolver.resolve("nextItemsConnection { nodes { _id } }")).to eq []
      expect(resolver.resolve("next { _id }")).to be_nil
    end

    it "returns null for previous it does not exist" do
      resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item1.id.to_s
      expect(resolver.resolve("previous { _id }")).to be_nil
    end

    it "returns empty array for previous items if there is none" do
      resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item1.id.to_s
      expect(resolver.resolve("previousItemsConnection { nodes { _id } }")).to eq []
    end

    it "returns all previous items starting from the closest one" do
      resolver = GraphQLTypeTester.new(module_item5, current_user: @teacher)
      expect(resolver.resolve("previousItemsConnection { nodes { _id } }")).to eq(
        [module_item4, module_item3, module_item2, module_item1].map { |i| i.id.to_s }
      )
    end

    it "returns all next items starting from the closest one" do
      resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
      expect(resolver.resolve("nextItemsConnection { nodes { _id } }")).to eq(
        [module_item2, module_item3, module_item4, module_item5].map { |i| i.id.to_s }
      )
    end
  end

  context "module item content" do
    def verify_module_item_works(module_item)
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item.id.to_s
    end

    it "works for assignments" do
      assignment = assignment_model({ context: course })
      module_item = module1.add_item({ type: "Assignment", id: assignment.id }, nil, position: 1)
      verify_module_item_works(module_item)
    end

    it "works for discussions" do
      discussion = discussion_topic_model({ context: course })
      module_item = module1.add_item({ type: "DiscussionTopic", id: discussion.id }, nil, position: 1)
      verify_module_item_works(module_item)
    end

    it "works for quizzes" do
      quiz = quiz_model({ course: })
      module_item = module1.add_item({ type: "Quiz", id: quiz.id }, nil, position: 1)
      verify_module_item_works(module_item)
    end

    it "works for pages" do
      page = wiki_page_model({ course: })
      module_item = module1.add_item({ type: "WikiPage", id: page.id }, nil, position: 1)
      verify_module_item_works(module_item)
    end

    it "works for files" do
      file = attachment_with_context(course)
      module_item = module1.add_item({ type: "Attachment", id: file.id }, nil, position: 1)
      verify_module_item_works(module_item)
    end

    it "works for external urls" do
      module_item = module1.content_tags.create!(
        tag_type: "context_module",
        content_type: "ExternalUrl",
        context_id: course.id,
        context_type: "Course",
        title: "Test Title",
        url: "https://google.com"
      )
      verify_module_item_works(module_item)
    end

    it "works for external tools" do
      external_tool = external_tool_model(context: course)
      module_item = module1.add_item({ type: "ContextExternalTool", id: external_tool.id }, nil, position: 1)
      verify_module_item_works(module_item)
    end

    it "works for module external tools" do
      module_item = module1.content_tags.create!(
        tag_type: "context_module",
        content_type: "ContextExternalTool",
        context_id: course.id,
        context_type: "Course",
        title: "Test Title",
        url: "https://google.com"
      )
      verify_module_item_works(module_item)
    end

    it "works for sub headings" do
      module_item = module1.add_item({ type: "SubHeader", title: "WHOA!" }, nil, position: 1)
      expect(
        GraphQLTypeTester.new(module_item, current_user: @teacher)
           .resolve("content { ... on SubHeader { title } }")
      ).to eq module_item.title
    end

    it "shows estimated_duration" do
      assignment = assignment_model({ context: course })
      EstimatedDuration.create!(assignment:, duration: 1.hour + 30.minutes)
      module_item = module1.add_item({ type: "Assignment", id: assignment.id }, nil, position: 1)
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("estimatedDuration")).to eq (1.hour + 30.minutes).iso8601
    end

    it "does not show estimated_duration when missing" do
      assignment = assignment_model({ context: course })
      module_item = module1.add_item({ type: "Assignment", id: assignment.id }, nil, position: 1)
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("estimatedDuration")).to be_nil
    end
  end

  context "assignments" do
    let_once(:assignment) { assignment_model({ context: course }) }
    let_once(:module_item) { module1.add_item({ type: "Assignment", id: assignment.id }, nil, position: 1) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("content { title }")).to eq module_item.title
      expect(resolver.resolve("content { type }")).to eq "Assignment"
      expect(resolver.resolve("content { pointsPossible }")).to eq module_item.content.points_possible
      expect(resolver.resolve("content { published }")).to eq module_item.content.published?
      expect(resolver.resolve("content { canUnpublish }")).to eq module_item.content.can_unpublish?
      expect(resolver.resolve("content { canDuplicate }")).to eq module_item.content.can_duplicate?
    end
  end

  context "discussions" do
    let_once(:discussion_topic) { discussion_topic_model({ context: course }) }
    let_once(:module_item) { module1.add_item({ type: "DiscussionTopic", id: discussion_topic.id }, nil, position: 1) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("content { title }")).to eq module_item.title
      expect(resolver.resolve("content { type }")).to eq "DiscussionTopic"
      expect(resolver.resolve("content { published }")).to eq module_item.content.published?
      expect(resolver.resolve("content { canUnpublish }")).to eq module_item.content.can_unpublish?
      expect(resolver.resolve("content { canDuplicate }")).to be true
    end

    context "graded discussions" do
      it "works" do
        assignment = assignment_model({ context: course })
        discussion_topic.assignment = assignment
        discussion_topic.save!
        module_item.reload
        resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
        expect(resolver.resolve("content { title }")).to eq module_item.title
        expect(resolver.resolve("content { type }")).to eq "DiscussionTopic"
        expect(resolver.resolve("content { pointsPossible }")).to eq module_item.content.assignment.points_possible
        expect(resolver.resolve("content { canDuplicate }")).to be true
      end
    end
  end

  context "quizzes" do
    let_once(:quiz) { quiz_model({ course: }) }
    let_once(:module_item) { module1.add_item({ type: "Quiz", id: quiz.id }, nil, position: 1) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("content { title }")).to eq module_item.title
      expect(resolver.resolve("content { type }").to_s).to eq "Quizzes::Quiz"
      expect(resolver.resolve("content { pointsPossible }")).to eq module_item.content.points_possible
      expect(resolver.resolve("content { canDuplicate }")).to be false
    end
  end

  context "module text sub header" do
    let_once(:module_item) { module1.add_item({ type: "ContextModuleSubHeader", title: "Sub Header" }, nil, position: 1) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("content { title }")).to eq module_item.title
      expect(resolver.resolve("content { type }")).to eq "ContentTag"
      expect(resolver.resolve("content { published }")).to be module_item.active?
      expect(resolver.resolve("content { canUnpublish }")).to be true
      expect(resolver.resolve("content { canDuplicate }")).to be false
    end
  end

  context "external url" do
    let_once(:module_item) { module1.add_item({ type: "ExternalUrl", title: "External URL", url: "https://example.com" }, nil, position: 1) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item, current_user: @teacher)
      expect(resolver.resolve("content { title }")).to eq module_item.title
      expect(resolver.resolve("content { type }")).to eq "ContentTag"
      expect(resolver.resolve("content { published }")).to be module_item.active?
      expect(resolver.resolve("content { canUnpublish }")).to be true
      expect(resolver.resolve("content { canDuplicate }")).to be false
    end
  end

  context "blueprint courses" do
    before do
      @course_1 = Course.create!(name: "Course 1")
      @course_2 = Course.create!(name: "Course 2")

      @teacher_1 = User.create!(name: "Teacher 1")
      @course_1.enroll_teacher(@teacher_1).accept!
      @course_2.enroll_teacher(@teacher_1).accept!

      @module_1 = @course_1.context_modules.create!(name: "Module the First", position: 1)
      @original_assmt = @course_1.assignments.create!(
        title: "blah", description: "bloo", points_possible: 27
      )

      @module_1.add_item({ type: "Assignment", id: @original_assmt.id }, nil, position: 1)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course_1)
      @tag = @template.create_content_tag_for!(@original_assmt)

      @module_2 = @course_2.context_modules.create!(name: "Module the First", position: 1)
      @copy_assmt = @course_2.assignments.create!(
        title: "blah", description: "bloo", points_possible: 27
      )

      @module_2.add_item({ type: "Assignment", id: @copy_assmt.id }, nil, position: 1)
      @template.add_child_course!(@course_2)
      @copy_assmt.migration_id = @tag.migration_id
      @copy_assmt.save!

      @module_item = ContentTag.find_by!(content_id: @original_assmt.id, context_id: @course_1.id)
      @module_item_copy = ContentTag.find_by!(content_id: @copy_assmt.id, context_id: @course_2.id)
    end

    context "returns false" do
      context "for the master course" do
        it "isLockedByMasterCourse" do
          resolver = GraphQLTypeTester.new(@module_item, current_user: @teacher_1)
          expect(resolver.resolve("content { isLockedByMasterCourse }")).to be false
        end
      end

      context "for the child course" do
        it "isLockedByMasterCourse" do
          resolver = GraphQLTypeTester.new(@module_item_copy, current_user: @teacher_1)
          expect(resolver.resolve("content { isLockedByMasterCourse }")).to be false
        end
      end
    end

    context "returns true" do
      before do
        mc_tag = @template.content_tag_for(@original_assmt)
        mc_tag.use_default_restrictions = true
        mc_tag.restrictions = { content: true, points: true, due_dates: false, availability_dates: false }
        mc_tag.save!
      end

      context "for the master course" do
        it "isLockedByMasterCourse" do
          resolver = GraphQLTypeTester.new(@module_item, current_user: @teacher_1)
          expect(resolver.resolve("content { isLockedByMasterCourse }")).to be true
        end
      end

      context "for the child course" do
        it "isLockedByMasterCourse" do
          resolver = GraphQLTypeTester.new(@module_item_copy, current_user: @teacher_1)
          expect(resolver.resolve("content { isLockedByMasterCourse }")).to be true
        end
      end
    end
  end
end

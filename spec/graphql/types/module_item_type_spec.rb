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
    let_once(:module_item2) { module1.add_item({ type: "assignment", id: assign2.id }, nil, position: 2) }
    let_once(:module_item3) { module1.add_item({ type: "assignment", id: assign3.id }, nil, position: 3) }

    it "works" do
      resolver = GraphQLTypeTester.new(module_item2, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item2.id.to_s
      expect(resolver.resolve("previous { _id }")).to eq module_item1.id.to_s
      expect(resolver.resolve("next { _id }")).to eq module_item3.id.to_s
    end

    it "returns null for next it does not exist" do
      resolver = GraphQLTypeTester.new(module_item3, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item3.id.to_s
      expect(resolver.resolve("next { _id }")).to be_nil
    end

    it "returns null for previous it does not exist" do
      resolver = GraphQLTypeTester.new(module_item1, current_user: @teacher)
      expect(resolver.resolve("_id")).to eq module_item1.id.to_s
      expect(resolver.resolve("previous { _id }")).to be_nil
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
  end
end

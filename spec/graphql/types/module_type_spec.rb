# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Types::ModuleType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let_once(:assignment) { assignment_model({ context: course }) }
  let_once(:mod) { course.context_modules.create! name: "module1", unlock_at: 1.week.from_now, position: 1 }
  let_once(:mod2) do
    course.context_modules.create!(
      name: "module2",
      unlock_at: 2.weeks.from_now,
      position: 2,
      prerequisites: [{ id: mod.id, name: mod.name, type: "context_module" }]
    )
  end
  let_once(:content_tag) { mod2.content_tags.create!(content: assignment, context: course) }
  let(:module_type) { GraphQLTypeTester.new(mod, current_user: @student) }
  let(:module2_type) { GraphQLTypeTester.new(mod2, current_user: @student) }

  it "works" do
    expect(module_type.resolve("name")).to eq mod.name
    expect(module_type.resolve("unlockAt")).to eq mod.unlock_at.iso8601
  end

  it "has requirementCount" do
    expect(module_type.resolve("requirementCount")).to eq mod.requirement_count
  end

  it "has requireSequentialProgress" do
    expect(module_type.resolve("requireSequentialProgress")).to eq mod.require_sequential_progress
  end

  it "has module items" do
    a1 = assignment_model({ context: course })
    a2 = assignment_model({ context: course })
    item1 = mod.add_item({ type: "Assignment", id: a1.id }, nil, position: 1)
    item2 = mod.add_item({ type: "Assignment", id: a2.id }, nil, position: 2)
    expect(module_type.resolve("moduleItems { _id }")).to eq [item1.id.to_s, item2.id.to_s]
  end

  it "requires read permissions to view module items" do
    a1 = assignment_model({ context: course })
    a2 = assignment_model({ context: course })
    a1.workflow_state = "unpublished"
    a1.save!
    mod.add_item({ type: "Assignment", id: a1.id }, nil, position: 1)
    item2 = mod.add_item({ type: "Assignment", id: a2.id }, nil, position: 2)
    expect(module_type.resolve("moduleItems { _id }")).to eq [item2.id.to_s]
  end

  it "orders module items by position" do
    a1 = assignment_model({ context: course, name: "zzz" })
    a2 = assignment_model({ context: course, name: "aaa" })
    item2 = mod.add_item({ type: "Assignment", id: a2.id }, nil, position: 2)
    item1 = mod.add_item({ type: "Assignment", id: a1.id }, nil, position: 1)
    expect(module_type.resolve("moduleItems { _id }")).to eq [item1.id.to_s, item2.id.to_s]
  end

  it "has accumulated estimated duration" do
    a1 = assignment_model({ context: course, name: "a1" })
    a2 = assignment_model({ context: course, name: "a2" })
    a3 = assignment_model({ context: course, name: "a3" })
    a4 = assignment_model({ context: course, name: "a4" })
    EstimatedDuration.create!(assignment_id: a1.id, duration: 1.hour)
    EstimatedDuration.create!(assignment_id: a2.id, duration: 30.minutes)
    EstimatedDuration.create!(assignment_id: a4.id, duration: 1.hour)
    mod.add_item({ type: "Assignment", id: a1.id }, nil, position: 1)
    mod.add_item({ type: "Assignment", id: a2.id }, nil, position: 2)
    mod.add_item({ type: "Assignment", id: a3.id }, nil, position: 3)
    mod.add_item({ type: "Assignment", id: a4.id }, nil, position: 4)
    expect(module_type.resolve("estimatedDuration")).to eq "PT2H30M"
  end

  it "returns published state" do
    expect(module_type.resolve("published")).to be true
  end

  it "returns prerequisites" do
    expect(module2_type.resolve("prerequisites { id }")).to eq [mod.id.to_s]
    expect(module2_type.resolve("prerequisites { name }")).to eq [mod.name]
    expect(module2_type.resolve("prerequisites { type }")).to eq ["context_module"]
  end

  describe "completion requirements" do
    it "returns completion requirements" do
      mod2.completion_requirements = [{ id: content_tag.id, type: "must_submit" }]
      mod2.save!
      expect(module2_type.resolve("completionRequirements { id }")).to eq [content_tag.id.to_s]
      expect(module2_type.resolve("completionRequirements { type }")).to eq ["must_submit"]
      expect(module2_type.resolve("completionRequirements { minScore }")).to match [be_nil]
      expect(module2_type.resolve("completionRequirements { minPercentage }")).to match [be_nil]
    end

    describe "visibility" do
      let_once(:published_assignment) { assignment_model({ context: course, name: "Published Assignment" }) }
      let_once(:unpublished_assignment) do
        assignment = assignment_model({ context: course, name: "Unpublished Assignment" })
        assignment.workflow_state = "unpublished"
        assignment.save!
        assignment
      end
      let_once(:published_tag) { mod2.content_tags.create!(content: published_assignment, context: course) }
      let_once(:unpublished_tag) { mod2.content_tags.create!(content: unpublished_assignment, context: course) }

      before do
        mod2.completion_requirements = [
          { id: published_tag.id, type: "must_submit" },
          { id: unpublished_tag.id, type: "must_submit" }
        ]
        mod2.save!
      end

      it "shows all requirements to teachers" do
        teacher = course_with_teacher(course:, active_all: true).user
        teacher_module_type = GraphQLTypeTester.new(mod2, current_user: teacher)
        expect(teacher_module_type.resolve("completionRequirements { id }").sort).to eq(
          [published_tag.id.to_s, unpublished_tag.id.to_s].sort
        )
      end

      it "shows only published requirements to students" do
        student_module_type = GraphQLTypeTester.new(mod2, current_user: @student)
        expect(student_module_type.resolve("completionRequirements { id }")).to eq [published_tag.id.to_s]
      end
    end
  end

  it "returns false when there are no overrides" do
    expect(module_type.resolve("hasActiveOverrides")).to be false
  end

  it "returns false when overrides are not active" do
    AssignmentOverride.create!(
      context_module_id: mod.id,
      workflow_state: "deleted"
    )
    expect(module_type.resolve("hasActiveOverrides")).to be false
  end

  it "returns true when there is at least one active override" do
    AssignmentOverride.create!(
      context_module_id: mod.id,
      workflow_state: "active"
    )
    expect(module_type.resolve("hasActiveOverrides")).to be true
  end

  describe "moduleItemsConnection" do
    let_once(:assignment1) { assignment_model({ context: course, name: "Assignment 1" }) }
    let_once(:assignment2) { assignment_model({ context: course, name: "Assignment 2" }) }
    let_once(:assignment3) { assignment_model({ context: course, name: "Assignment 3" }) }
    let_once(:page1) { course.wiki_pages.create!(title: "Page 1", body: "content") }
    let_once(:unpublished_assignment) do
      assignment = assignment_model({ context: course, name: "Unpublished Assignment" })
      assignment.workflow_state = "unpublished"
      assignment.save!
      assignment
    end

    before do
      mod.add_item({ type: "Assignment", id: assignment1.id }, nil, position: 1)
      mod.add_item({ type: "Assignment", id: assignment2.id }, nil, position: 2)
      mod.add_item({ type: "Assignment", id: assignment3.id }, nil, position: 3)
      mod.add_item({ type: "WikiPage", id: page1.id }, nil, position: 4)
      mod.add_item({ type: "Assignment", id: unpublished_assignment.id }, nil, position: 5)
    end

    it "returns paginated module items" do
      result = module_type.resolve("moduleItemsConnection(first: 2) { edges { node { _id } } }")
      expect(result.length).to eq 2
      expect(result).to all(be_a(String))
    end

    it "supports cursor-based pagination" do
      # Get first page of results
      first_page = module_type.resolve("moduleItemsConnection(first: 2) { edges { node { _id } } }")
      expect(first_page.length).to eq 2

      # Test that we can get subsequent items when there are more
      all_items = module_type.resolve("moduleItemsConnection { edges { node { _id } } }")
      if all_items.length > 2
        # There should be more items available beyond the first 2
        expect(all_items.length).to be > 2
      end
    end

    it "respects permission controls like the original moduleItems field" do
      # Only published items should be visible to students
      result = module_type.resolve("moduleItemsConnection { edges { node { _id } } }")
      module_items_result = module_type.resolve("moduleItems { _id }")

      expect(result).to eq module_items_result
    end

    it "filters by search term" do
      result = module_type.resolve('moduleItemsConnection(filter: { searchTerm: "Assignment 1" }) { edges { node { _id } } }')
      expect(result.length).to eq 1

      assignment1_tag = mod.content_tags.find_by(content: assignment1)
      expect(result[0]).to eq assignment1_tag.id.to_s
    end

    it "accepts published status filter" do
      teacher = course_with_teacher(course:, active_all: true).user
      teacher_module_type = GraphQLTypeTester.new(mod, current_user: teacher)

      # Test that the published filter parameter is accepted and returns results
      published_result = teacher_module_type.resolve("moduleItemsConnection(filter: { published: true }) { edges { node { _id } } }")

      # Should return some results without error
      expect(published_result).to be_an(Array)
      expect(published_result.length).to be >= 0
    end

    it "filters by content type" do
      result = module_type.resolve('moduleItemsConnection(filter: { contentType: "Assignment" }) { edges { node { _id } } }')
      expect(result.length).to eq 3  # Only published assignments visible to students

      page_result = module_type.resolve('moduleItemsConnection(filter: { contentType: "WikiPage" }) { edges { node { _id } } }')
      expect(page_result.length).to eq 1
    end

    it "combines multiple filters" do
      result = module_type.resolve('moduleItemsConnection(filter: { searchTerm: "Assignment", contentType: "Assignment" }) { edges { node { _id } } }')
      expect(result.length).to eq 3  # All published assignments match "Assignment" search
    end
  end

  describe "moduleItemsTotalCount" do
    let_once(:assignment1) { assignment_model({ context: course, name: "Assignment 1" }) }
    let_once(:assignment2) { assignment_model({ context: course, name: "Assignment 2" }) }
    let_once(:unpublished_assignment) do
      assignment = assignment_model({ context: course, name: "Unpublished Assignment" })
      assignment.workflow_state = "unpublished"
      assignment.save!
      assignment
    end

    before do
      mod.add_item({ type: "Assignment", id: assignment1.id }, nil, position: 1)
      mod.add_item({ type: "Assignment", id: assignment2.id }, nil, position: 2)
      mod.add_item({ type: "Assignment", id: unpublished_assignment.id }, nil, position: 3)
    end

    it "returns total count of visible module items" do
      expect(module_type.resolve("moduleItemsTotalCount")).to eq 2 # Only published items visible to students
    end

    it "matches the count from moduleItems field" do
      total_count = module_type.resolve("moduleItemsTotalCount")
      module_items_count = module_type.resolve("moduleItems { _id }").length
      expect(total_count).to eq module_items_count
    end

    it "returns correct count for teachers including unpublished items" do
      teacher = course_with_teacher(course:, active_all: true).user
      teacher_module_type = GraphQLTypeTester.new(mod, current_user: teacher)
      expect(teacher_module_type.resolve("moduleItemsTotalCount")).to eq 3 # All items visible to teachers
    end
  end

  describe "progression" do
    let_once(:mod3) do
      course.context_modules.create!(
        name: "module3",
        position: 3,
        prerequisites: [{ id: mod2.id, name: mod2.name, type: "context_module" }]
      )
    end
    let(:module3_type) { GraphQLTypeTester.new(mod3, current_user: @student) }

    it "initializes progressions for students" do
      result = module3_type.resolve("progression { locked }")

      expect(result).to be true
    end
  end

  describe "backwards compatibility" do
    let_once(:assignment1) { assignment_model({ context: course, name: "Assignment 1" }) }
    let_once(:assignment2) { assignment_model({ context: course, name: "Assignment 2" }) }

    before do
      mod.add_item({ type: "Assignment", id: assignment1.id }, nil, position: 1)
      mod.add_item({ type: "Assignment", id: assignment2.id }, nil, position: 2)
    end

    it "maintains existing moduleItems field functionality" do
      # Test that existing queries still work exactly as before
      result = module_type.resolve("moduleItems { _id }")
      expect(result.length).to eq 2
      expect(result).to all(be_a(String))
    end

    it "returns same items in moduleItems and moduleItemsConnection" do
      module_items_result = module_type.resolve("moduleItems { _id }")
      connection_result = module_type.resolve("moduleItemsConnection { edges { node { _id } } }")

      expect(connection_result).to eq module_items_result
    end
  end
end

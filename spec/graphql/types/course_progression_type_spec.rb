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

require_relative "../graphql_spec_helper"

describe Types::CourseProgressionType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:student) { student_in_course(course:, active_all: true).user }
  let_once(:module1) { course.context_modules.create! name: "module1" }
  let_once(:assign1_1) { course.assignments.create(title: "a1", workflow_state: "published") }
  let_once(:module_item1_1) { module1.add_item({ type: "assignment", id: assign1_1.id }, nil, position: 1) }
  let_once(:assign1_2) { course.assignments.create(title: "a2", workflow_state: "published") }
  let_once(:module_item1_2) { module1.add_item({ type: "assignment", id: assign1_2.id }, nil, position: 2) }

  let_once(:module2) { course.context_modules.create! name: "module2" }
  let_once(:assign2_1) { course.assignments.create(title: "a3", workflow_state: "published") }
  let_once(:module_item2_1) { module2.add_item({ type: "assignment", id: assign2_1.id }, nil, position: 1) }

  let_once(:normalized_requirement_completed_count) { 3 }
  let_once(:normalized_requirement_count) { 5 }
  let_once(:progress_percent) { 60.0 }
  let(:incomplete_items_for_modules) do
    [
      {
        module: module1,
        items: [module_item1_1, module_item1_2]
      },
      {
        module: module2,
        items: [module_item2_1]
      }
    ]
  end

  let(:course_progress_helper) do
    course_progress_helper = double(CourseProgress.name)
    allow(course_progress_helper).to receive_messages(
      can_evaluate_progression?: true,
      normalized_requirement_completed_count:,
      normalized_requirement_count:,
      progress_percent:,
      incomplete_items_for_modules:
    )
    course_progress_helper
  end

  let(:user_type) { GraphQLTypeTester.new(student, course:, current_user: student) }

  before do
    allow(CourseProgress).to receive(:new).and_return(course_progress_helper)
  end

  it "returns requirement data from CourseProgress correctly" do
    expect(user_type.resolve("courseProgression { requirements { total } }")).to eq normalized_requirement_count
    expect(user_type.resolve("courseProgression { requirements { completed } }")).to eq normalized_requirement_completed_count
    expect(user_type.resolve("courseProgression { requirements { completionPercentage } }")).to eq progress_percent
  end

  it "returns incomplete modules from CourseProgress correctly" do
    expect(
      user_type.resolve("courseProgression { incompleteModulesConnection { nodes { module { _id } } } }")
    ).to eq([module1, module2].map { |mod| mod.id.to_s })
  end

  it "returns incomplete module items from CourseProgress correctly" do
    expect(
      user_type.resolve("courseProgression { incompleteModulesConnection { nodes { incompleteItemsConnection { nodes { _id } } } } }")
    ).to eq([
              [module_item1_1, module_item1_2].map { |item| item.id.to_s },
              [module_item2_1].map { |item| item.id.to_s }
            ])
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Types::ModuleProgressionType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let_once(:teacher) { @teacher }
  let_once(:student) { @student }
  let_once(:module1) { course.context_modules.create!(name: "module1", position: 1) }
  let_once(:module2) { course.context_modules.create!(name: "module2", position: 2) }

  # Create some module items and requirements
  let_once(:assignment) { assignment_model(context: course) }
  let_once(:module_item) do
    module1.add_item(type: "Assignment", id: assignment.id)
    module1.completion_requirements = [{ id: module1.content_tags.first.id, type: "must_submit" }]
    module1.save!
    module1.content_tags.first
  end

  # Create a progression for the student
  let_once(:progression) do
    progression = module1.context_module_progressions.create!(user: student)
    progression.requirements_met = [{ id: module_item.id, type: "must_submit" }]
    progression.workflow_state = "completed"
    progression.completed_at = Time.zone.now
    progression.evaluated_at = Time.zone.now
    progression.current = true
    progression.save!
    progression
  end

  let(:progression_type) { GraphQLTypeTester.new(progression, current_user: student) }
  let(:teacher_progression_type) { GraphQLTypeTester.new(progression, current_user: teacher) }

  it "works" do
    expect(progression_type.resolve("_id")).to eq progression.id.to_s
    expect(progression_type.resolve("workflowState")).to eq progression.workflow_state
    expect(progression_type.resolve("completedAt")).to eq progression.completed_at.iso8601
    expect(progression_type.resolve("evaluatedAt")).to eq progression.evaluated_at.iso8601
    expect(progression_type.resolve("current")).to eq progression.current
    expect(progression_type.resolve("collapsed")).to eq progression.collapsed
  end

  it "returns boolean state methods" do
    expect(progression_type.resolve("completed")).to eq progression.completed?
    expect(progression_type.resolve("unlocked")).to eq progression.unlocked?
    expect(progression_type.resolve("locked")).to eq progression.locked?
    expect(progression_type.resolve("started")).to eq progression.started?
  end

  it "returns requirements_met" do
    requirement = progression.requirements_met.first
    result = progression_type.resolve("requirementsMet { id }")
    expect(result.first).to eq requirement[:id].to_s
    result = progression_type.resolve("requirementsMet { type }")
    expect(result.first).to eq requirement[:type]
  end

  it "returns incomplete_requirements" do
    # First add an incomplete requirement
    progression.incomplete_requirements = [{ id: module_item.id, type: "min_score", score: 5 }]
    progression.save!

    requirement = progression.incomplete_requirements.first
    result = progression_type.resolve("incompleteRequirements { id }")
    expect(result.first).to eq requirement[:id].to_s
    result = progression_type.resolve("incompleteRequirements { type }")
    expect(result.first).to eq requirement[:type]
    result = progression_type.resolve("incompleteRequirements { score }")
    expect(result.first).to eq requirement[:score]
  end

  it "returns the associated context_module" do
    expect(progression_type.resolve("contextModule { _id }")).to eq module1.id.to_s
    expect(progression_type.resolve("contextModule { name }")).to eq module1.name
  end

  it "returns the associated user" do
    expect(progression_type.resolve("user { _id }")).to eq student.id.to_s
  end

  context "permissions" do
    it "allows students to view their own progressions" do
      expect(progression_type.resolve("_id")).to eq progression.id.to_s
    end

    it "allows teachers to view student progressions" do
      expect(teacher_progression_type.resolve("_id")).to eq progression.id.to_s
    end

    it "restricts other students from viewing progressions" do
      other_student = user_factory(active_all: true)
      course.enroll_student(other_student, enrollment_state: "active")
      other_progression_type = GraphQLTypeTester.new(progression, current_user: other_student)

      # This should return nil since other students shouldn't be able to view each other's progressions
      expect(other_progression_type.resolve("_id")).to be_nil
    end
  end
end

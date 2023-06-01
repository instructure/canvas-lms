# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::SetModuleItemCompletion do
  let(:course) { Course.create! }
  let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
  let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

  let(:assignment) { course.assignments.create!(title: "an assignment") }
  let(:module1) { course.context_modules.create!(name: "a module") }
  let(:module2) { course.context_modules.create!(name: "another module") }
  let(:unrelated_module) { course.context_modules.create!(name: "still another module") }

  let(:module1_assignment_item) { module1.content_tags.find_by!(content_type: "Assignment", content_id: assignment.id) }
  let(:module2_assignment_item) { module2.content_tags.find_by!(content_type: "Assignment", content_id: assignment.id) }

  before do
    module1.add_item(id: assignment.id, type: "assignment")
    module1.completion_requirements = [{ id: module1_assignment_item.id, type: "must_mark_done" }]
    module1.save!

    module2.add_item(id: assignment.id, type: "assignment")
    module2.completion_requirements = [{ id: module2_assignment_item.id, type: "must_mark_done" }]
    module2.save!

    module1.context_module_progressions.create!(user: student)
    module2.context_module_progressions.create!(user: student)
    unrelated_module.context_module_progressions.create!(user: student)
  end

  def mutation_str(module_id: module1.id, item_id: module1_assignment_item.id, done: true)
    input_string = "moduleId: #{module_id} itemId: #{item_id} done: #{done}"

    <<~GQL
      mutation {
        setModuleItemCompletion(input: {
          #{input_string}
        }) {
          moduleItem {
            _id
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  context "when executed by a user with permission to view the module and its owning course" do
    before { course.offer! }

    let(:context) { { current_user: student } }

    describe "returned values" do
      it "returns the ID of the module item in the moduleItem field" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result.dig("data", "setModuleItemCompletion", "moduleItem", "_id")).to eq module1_assignment_item.id.to_s
      end
    end

    describe "model changes" do
      context "when 'done' is set to true" do
        it "marks the progression as done for the specified module and item if the requirement is mark-as-done" do
          CanvasSchema.execute(mutation_str(module_id: module1.id, item_id: module1_assignment_item.id), context:)

          module1_progression = module1.context_module_progressions.find_by!(user: student)
          expect(module1_progression).to be_finished_item(module1_assignment_item)
        end

        it "does not update the item if the requirement is not mark-as-done" do
          module1.completion_requirements = [{ id: module1_assignment_item.id, type: "must_read" }]
          module1.save!

          CanvasSchema.execute(mutation_str(module_id: module1.id, item_id: module1_assignment_item.id), context:)

          module1_progression = module1.context_module_progressions.find_by!(user: student)
          expect(module1_progression).not_to be_finished_item(module1_assignment_item)
        end

        it "does not update the item in other modules" do
          CanvasSchema.execute(mutation_str(module_id: module1.id, item_id: module1_assignment_item.id), context:)

          module2_progression = module2.context_module_progressions.find_by!(user: student)
          expect(module2_progression).not_to be_finished_item(module2_assignment_item)
        end
      end

      context "when 'done' is set to false" do
        before do
          assignment.context_module_action(student, :done)
        end

        it "marks the progression as undone for the specified module and item" do
          CanvasSchema.execute(mutation_str(module_id: module1.id, item_id: module1_assignment_item.id, done: false), context:)

          module1_progression = module1.context_module_progressions.find_by!(user: student)
          expect(module1_progression).not_to be_finished_item(module1_assignment_item)
        end

        it "does not affect the item as stored in other modules" do
          CanvasSchema.execute(mutation_str(module_id: module1.id, item_id: module1_assignment_item.id, done: false), context:)

          module2_progression = module2.context_module_progressions.find_by!(user: student)
          expect(module2_progression).to be_finished_item(module2_assignment_item)
        end
      end
    end

    describe "error handling" do
      it "returns an error if no module matches the given module ID" do
        result = CanvasSchema.execute(mutation_str(module_id: 0), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns an error if no module item matches the given item ID" do
        result = CanvasSchema.execute(mutation_str(item_id: 0), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns an error if the given module does not contain the given item" do
        result = CanvasSchema.execute(mutation_str(module_id: unrelated_module.id), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns an error if the given module is not visible to the caller" do
        locked_module = course.context_modules.create!(name: "locked")
        locked_assignment = course.assignments.create!(title: "also locked")
        locked_module.add_item(id: locked_assignment.id, type: "assignment")

        student.context_module_progressions.create!(context_module: locked_module, workflow_state: "locked")

        result = CanvasSchema.execute(mutation_str(module_id: unrelated_module.id), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns an error if marking as not-done and no progression object is found" do
        module1.context_module_progressions.find_by(user: student).destroy

        result = CanvasSchema.execute(mutation_str(module_id: module1.id, done: false), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end
  end

  context "when the caller does not have permission to read the course" do
    it "returns an error" do
      result = CanvasSchema.execute(mutation_str, context: { current_user: student })
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "does not return data pertaining to the module item" do
      result = CanvasSchema.execute(mutation_str, context: { current_user: student })
      expect(result.dig("data", "setModuleItemCompletion")).to be_nil
    end
  end
end

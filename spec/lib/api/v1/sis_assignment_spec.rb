# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

class SisAssignmentHarness
  include Api::V1::SisAssignment
end

describe Api::V1::SisAssignment do
  subject(:generator) { SisAssignmentHarness.new }

  context "#sis_assignments_json" do
    let(:course_1) { course_factory }
    let(:assignment_1) { assignment_model(course: course_factory) }

    let(:assignment_override_1) do
      assignment_override_model(assignment: assignment_1)
    end

    let(:assignment_override_2) do
      assignment_override_model(assignment: assignment_1)
    end

    let(:assignment_overrides) do
      allow(assignment_override_1).to receive_messages(set_type: "CourseSection", set_id: 1)

      allow(assignment_override_2).to receive_messages(set_type: "CourseSection", set_id: 2)

      [
        assignment_override_1,
        assignment_override_2
      ]
    end

    let(:course_section_1) { CourseSection.new }
    let(:course_section_2) { CourseSection.new }
    let(:course_section_3) { CourseSection.new }

    let(:course_sections) do
      [
        course_section_1,
        course_section_2,
        course_section_3
      ]
    end

    before do
      allow(assignment_1).to receive(:locked_for?).and_return(false)

      allow(assignment_overrides).to receive_messages(
        loaded?: true,
        unlock_at: 15.days.ago,
        lock_at: 2.days.from_now
      )

      allow(course_section_1).to receive(:id).and_return(1)
      allow(course_section_2).to receive(:id).and_return(2)
      allow(course_section_3).to receive(:id).and_return(3)

      course_sections.each do |course_section|
        allow(course_section).to receive_messages(nonxlist_course: course_1,
                                                  crosslisted?: false)
      end

      allow(course_sections).to receive_messages(
        loaded?: true,
        active_course_sections: course_sections,
        association: OpenStruct.new(loaded?: true)
      )
    end

    it "creates assignment groups that have name and integration_data with proper data" do
      ag_name = "chumba choo choo"
      sis_source_id = "my super unique goo-id"
      integration_data = { "something" => "else", "foo" => { "bar" => "baz" } }
      assignment_group = AssignmentGroup.new(name: ag_name,
                                             sis_source_id:,
                                             integration_data:,
                                             group_weight: 8.7)
      allow(assignment_1).to receive(:assignment_group).and_return(assignment_group)
      result = subject.sis_assignments_json([assignment_1])
      expect(result[0]["assignment_group"]["name"]).to eq(ag_name)
      expect(result[0]["assignment_group"]["sis_source_id"]).to eq(sis_source_id)
      expect(result[0]["assignment_group"]["integration_data"]).to eq(integration_data)
      expect(result[0]["assignment_group"]["group_weight"]).to eq(8.7)
    end

    it "creates assignment groups where integration_data is nil" do
      ag_name = "too much tuna"
      sis_source_id = "some super cool id"
      assignment_group = AssignmentGroup.new(name: ag_name,
                                             sis_source_id:,
                                             integration_data: nil,
                                             group_weight: 8.7)
      allow(assignment_1).to receive(:assignment_group).and_return(assignment_group)
      result = subject.sis_assignments_json([assignment_1])
      expect(result[0]["assignment_group"]["name"]).to eq(ag_name)
      expect(result[0]["assignment_group"]["sis_source_id"]).to eq(sis_source_id)
      expect(result[0]["assignment_group"]["integration_data"]).to eq({})
      expect(result[0]["assignment_group"]["group_weight"]).to eq(8.7)
    end

    it "returns false for include_in_final_grade when omit_from_final_grade is true" do
      assignment_1[:omit_from_final_grade] = true
      assignment_1[:grading_type] = "points"
      assignments = [assignment_1]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]["include_in_final_grade"]).to be(false)
    end

    it "returns false for include_in_final_grade when grading_type is not_graded" do
      assignment_1[:omit_from_final_grade] = false
      assignment_1[:grading_type] = "not_graded"
      assignments = [assignment_1]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]["include_in_final_grade"]).to be(false)
    end

    it "returns true for include_in_final_grade when appropriate" do
      assignment_1[:omit_from_final_grade] = false
      assignment_1[:grading_type] = "points"
      assignments = [assignment_1]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]["include_in_final_grade"]).to be(true)
    end

    it "returns an empty hash for 0 assignments" do
      assignments = []
      expect(subject.sis_assignments_json(assignments)).to eq([])
    end

    context "returns hash when there are no courses" do
      let(:assignments) { [assignment_1] }
      let(:results) { subject.sis_assignments_json(assignments) }

      it { expect(results.size).to eq(1) }
      it { expect(results.first["id"]).to eq(assignment_1.id) }
    end

    it "displays all section overrides" do
      course = assignment_1.course
      new_section = course.course_sections.create!(name: "new section")
      create_section_override_for_assignment(assignment_1, course_section: course.default_section)
      create_section_override_for_assignment(assignment_1, course_section: new_section)

      result = generator.sis_assignments_json([assignment_1])

      expect(result[0]["sections"].size).to eq(2)
      expect(result[0]["sections"][0]["id"]).to eq(new_section.id)
      expect(result[0]["sections"][1]["id"]).to eq(course.default_section.id)
    end

    it "includes unlock_at and lock_at attributes" do
      result = generator.sis_assignments_json([assignment_1])

      expect(result[0]).to have_key("unlock_at")
      expect(result[0]).to have_key("lock_at")
    end

    it "includes unlock_at and lock_at attributes in section overrides" do
      create_section_override_for_assignment(assignment_1, unlock_at: 1.day.ago, lock_at: 1.day.from_now)
      assignment_1.active_assignment_overrides.reload

      result = generator.sis_assignments_json([assignment_1])

      expect(result[0]["sections"][0]["override"]).to have_key("unlock_at")
      expect(result[0]["sections"][0]["override"]).to have_key("lock_at")
    end

    it "can return an empty due_at" do
      assignment_1.due_at = nil
      assignment_1.save!

      assignments = Assignment.where(id: assignment_1.id)

      result = generator.sis_assignments_json(assignments)

      expect(result[0]["due_at"]).to be_nil
    end

    context "mastery paths overrides" do
      it "uses a mastery paths due date as the course due date" do
        due_at = Time.zone.parse("2017-02-08 22:11:10")
        assignment_1.update(due_at: nil)
        create_mastery_paths_override_for_assignment(assignment_1, due_at:)
        assignments = Assignment.where(id: assignment_1.id)
                                .preload(:active_assignment_overrides)

        result = generator.sis_assignments_json(assignments)

        expect(result[0]["due_at"]).to eq due_at
      end

      it "prefers the assignment due_at over an override" do
        assignment_due_at = Time.zone.parse("2017-03-08 22:11:10")
        assignment_1.update(due_at: assignment_due_at)

        override_due_at = Time.zone.parse("2017-02-08 22:11:10")
        create_mastery_paths_override_for_assignment(assignment_1, due_at: override_due_at)

        assignments = Assignment.where(id: assignment_1.id)
                                .preload(:active_assignment_overrides)

        result = generator.sis_assignments_json(assignments)

        expect(result[0]["due_at"]).to eq assignment_due_at
      end
    end

    context "student_overrides: true" do
      let(:course) { assignment_1.course }

      before do
        @student1 = student_in_course(course:, workflow_state: "active").user
        @student2 = student_in_course(course:, workflow_state: "active").user
        managed_pseudonym(@student2, sis_user_id: "SIS_ID_2", account: Account.default)

        due_at = Time.zone.parse("2017-02-08 22:11:10")
        @override = create_adhoc_override_for_assignment(assignment_1, [@student1, @student2], due_at:)
      end

      it "adds student assignment override information" do
        assignments = Assignment.where(id: assignment_1.id)
                                .preload(active_assignment_overrides: [assignment_override_students: [user: [:pseudonym]]])

        result = generator.sis_assignments_json(assignments, student_overrides: true)

        user_overrides = result[0]["user_overrides"]
        expect(user_overrides.size).to eq 1
        expect(user_overrides.first).to include({ "id" => @override.id, :due_at => @override.due_at })

        students = user_overrides.first["students"]
        expect(students).to include({ "user_id" => @student1.id, "sis_user_id" => nil })
        expect(students).to include({ "user_id" => @student2.id, "sis_user_id" => "SIS_ID_2" })
        expect(students.size).to eq 2
      end

      it "raises an error when active_assignment_overrides are not preloaded" do
        assignments = Assignment.where(id: assignment_1.id)

        expect do
          generator.sis_assignments_json(assignments, student_overrides: true)
        end.to raise_error(Api::V1::SisAssignment::UnloadedAssociationError)
      end

      it "raises an error when assignment_override_students are not preloaded" do
        assignments = Assignment.where(id: assignment_1.id).preload(:active_assignment_overrides)

        expect do
          generator.sis_assignments_json(assignments, student_overrides: true)
        end.to raise_error(Api::V1::SisAssignment::UnloadedAssociationError)
      end

      it "does not list student sis_ids when users are not preloaded" do
        assignments = Assignment.where(id: assignment_1.id)
                                .preload(active_assignment_overrides: [:assignment_override_students])

        user_overrides = generator.sis_assignments_json(assignments, student_overrides: true)[0]["user_overrides"]

        expect(user_overrides.first["students"].first).not_to have_key("sis_user_id")
      end

      it "provides an empty list when there are no overrides" do
        assignment_2 = assignment_model(course:)
        assignments = Assignment.where(id: assignment_2.id)
                                .preload(active_assignment_overrides: [assignment_override_students: [user: [:pseudonym]]])

        assignment_hash = generator.sis_assignments_json(assignments, student_overrides: true)[0]

        expect(assignment_hash["user_overrides"]).to eq []
      end
    end
  end
end

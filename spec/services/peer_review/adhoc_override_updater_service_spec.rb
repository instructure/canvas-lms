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

require "spec_helper"

RSpec.describe PeerReview::AdhocOverrideUpdaterService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:students) { create_users_in_course(course, 4, return_type: :record) }
  let(:initial_parent_override) do
    parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
    [students[0], students[1]].each do |student|
      parent_override.assignment_override_students.build(user: student)
    end
    parent_override.save!
    parent_override
  end
  let(:existing_override) do
    override = assignment_override_model(assignment: peer_review_sub_assignment, set_type: "ADHOC", parent_override_id: initial_parent_override.id)
    override.assignment_override_students.create!(user: students[0])
    override.assignment_override_students.create!(user: students[1])
    override
  end
  let(:due_at) { 1.week.from_now }
  let(:unlock_at) { 1.day.from_now }
  let(:lock_at) { 2.weeks.from_now }

  describe "#initialize" do
    let(:override_params) do
      {
        set_type: "ADHOC",
        id: existing_override.id
      }
    end

    let(:service) do
      described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )
    end

    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_params)
    end

    it "inherits from PeerReview::AdhocOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::AdhocOverrideCommonService)
    end
  end

  describe "#call" do
    context "with valid parameters" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id, students[2].id, students[3].id],
          due_at:,
          unlock_at:,
          lock_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        initial_parent_override.destroy
        parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        [students[0], students[2], students[3]].each do |student|
          parent_override.assignment_override_students.build(user: student)
        end
        parent_override.save!
      end

      it "returns the updated override" do
        result = service.call
        expect(result).to eq(existing_override)
        expect(result).to be_persisted
      end

      it "updates the student overrides correctly" do
        service.call
        existing_override.reload

        expected_student_ids = [students[0].id, students[2].id, students[3].id]
        actual_student_ids = existing_override.assignment_override_students.pluck(:user_id)
        expect(actual_student_ids).to match_array(expected_student_ids)
      end

      it "removes student overrides for students who are no longer in the list" do
        expect { service.call }.to change {
          existing_override.assignment_override_students.where(user_id: students[1].id).count
        }.from(1).to(0)
      end

      it "adds new students to the override" do
        expect { service.call }.to change {
          existing_override.assignment_override_students.where(user_id: students[2].id).count
        }.from(0).to(1)
      end

      it "updates the title based on new student count" do
        service.call
        existing_override.reload

        expected_title = AssignmentOverride.title_from_student_count(3)
        expect(existing_override.title).to eq(expected_title)
      end

      it "applies the updated dates to the override" do
        service.call
        existing_override.reload

        expect(existing_override.due_at).to eq(due_at)
        expect(existing_override.unlock_at).to eq(unlock_at)
        expect(existing_override.lock_at).to eq(lock_at)
        expect(existing_override.due_at_overridden).to be(true)
        expect(existing_override.unlock_at_overridden).to be(true)
        expect(existing_override.lock_at_overridden).to be(true)
      end

      it "wraps the operation in a transaction" do
        expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
        service.call
      end
    end

    context "when student list hasn't changed" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id, students[1].id],
          due_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "does not modify student overrides" do
        expect { service.call }.not_to change {
          existing_override.assignment_override_students.pluck(:user_id)
        }
      end

      it "still applies date updates" do
        service.call
        existing_override.reload
        expect(existing_override.due_at).to eq(due_at)
      end
    end

    context "when no student_ids are provided in params" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "ADHOC",
          due_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "falls back to existing student IDs from override set" do
        loaded_override = existing_override
        allow_any_instance_of(described_class).to receive(:find_override).and_return(loaded_override)
        expect(loaded_override).to receive(:set).at_least(:once).and_return(students[0..1])
        result = service.call
        expect(result).to eq(loaded_override)
      end

      it "does not change existing student overrides" do
        expect { service.call }.not_to change {
          existing_override.assignment_override_students.count
        }
      end
    end

    context "with mixed valid and invalid student IDs" do
      let(:non_course_student) { user_factory }
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id, non_course_student.id, 999_999, students[2].id]
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        initial_parent_override.destroy
        parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        [students[0], students[2]].each do |student|
          parent_override.assignment_override_students.build(user: student)
        end
        parent_override.save!
      end

      it "only includes valid course students" do
        service.call
        existing_override.reload

        expected_student_ids = [students[0].id, students[2].id]
        actual_student_ids = existing_override.assignment_override_students.pluck(:user_id)
        expect(actual_student_ids).to match_array(expected_student_ids)
      end

      it "updates title based on valid student count only" do
        service.call
        existing_override.reload

        expected_title = AssignmentOverride.title_from_student_count(2)
        expect(existing_override.title).to eq(expected_title)
      end
    end

    context "when override does not exist" do
      let(:override_params) do
        {
          id: 999_999,
          set_type: "ADHOC",
          student_ids: [students[0].id]
        }
      end
      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "raises OverrideNotFoundError" do
        expect { service.call }.to raise_error(PeerReview::OverrideNotFoundError, "Override does not exist")
      end
    end

    context "when override exists but is not ADHOC type" do
      let(:test_section) { add_section("Test Section", course:) }
      let!(:parent_section_override) do
        peer_review_sub_assignment.parent_assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set: test_section,
          title: "Section Override"
        )
      end
      let(:section_override) do
        peer_review_sub_assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set: test_section,
          title: "Section Override",
          parent_override: parent_section_override
        )
      end

      let(:override_params) do
        {
          id: section_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id]
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "raises OverrideNotFoundError" do
        expect { service.call }.to raise_error(PeerReview::OverrideNotFoundError, "Override does not exist")
      end
    end

    context "when student_ids is missing and override.set is nil" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "ADHOC"
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        loaded_override = existing_override
        allow(loaded_override).to receive(:set).and_return(nil)
        allow_any_instance_of(described_class).to receive(:find_override).and_return(loaded_override)
      end

      it "raises StudentIdsRequiredError" do
        expect { service.call }.to raise_error(PeerReview::StudentIdsRequiredError, "Student ids are required")
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_params) do
          {
            id: existing_override.id,
            set_type: "ADHOC",
            student_ids: [students[0].id],
            due_at: 1.day.from_now,
            unlock_at: 2.days.from_now
          }
        end

        let(:service) do
          described_class.new(
            peer_review_sub_assignment:,
            override: override_params
          )
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be before unlock date")
        end
      end
    end

    context "transaction rollback scenarios" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id, students[2].id]
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        initial_parent_override.destroy
        parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        [students[0], students[2]].each do |student|
          parent_override.assignment_override_students.build(user: student)
        end
        parent_override.save!
      end

      it "rolls back if student deletion fails" do
        allow_any_instance_of(described_class).to receive(:destroy_override_students).and_raise(ActiveRecord::StatementInvalid.new("Database error"))

        expect { service.call }.to raise_error(ActiveRecord::StatementInvalid)
        existing_override.reload
        expect(existing_override.assignment_override_students.pluck(:user_id)).to match_array([students[0].id, students[1].id])
      end

      it "rolls back if override save fails" do
        allow(existing_override).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(existing_override))
        allow(existing_override).to receive(:save).and_raise(ActiveRecord::RecordInvalid.new(existing_override))
        allow_any_instance_of(described_class).to receive(:find_override).and_return(existing_override)

        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
        existing_override.reload
        expect(existing_override.assignment_override_students.pluck(:user_id)).to match_array([students[0].id, students[1].id])
      end
    end
  end

  describe "#destroy_override_students" do
    let(:service) { described_class.new }

    context "when student IDs are provided" do
      it "destroys the specified assignment override students" do
        expect do
          service.destroy_override_students(existing_override, [students[0].id])
        end.to change { existing_override.assignment_override_students.count }.by(-1)

        remaining_student_ids = existing_override.assignment_override_students.pluck(:user_id)
        expect(remaining_student_ids).not_to include(students[0].id)
        expect(remaining_student_ids).to include(students[1].id)
      end
    end

    context "when student IDs array is empty" do
      it "does not destroy any students" do
        expect do
          service.destroy_override_students(existing_override, [])
        end.not_to change { existing_override.assignment_override_students.count }
      end
    end

    context "when student IDs is nil" do
      it "does not destroy any students" do
        expect do
          service.destroy_override_students(existing_override, nil)
        end.not_to change { existing_override.assignment_override_students.count }
      end
    end
  end

  describe "#find_override" do
    it "finds the correct ADHOC override by ID" do
      service = described_class.new(
        peer_review_sub_assignment:,
        override: { id: existing_override.id }
      )
      result = service.send(:find_override)
      expect(result).to eq(existing_override)
    end

    it "returns nil for non-existent override ID" do
      service = described_class.new(
        peer_review_sub_assignment:,
        override: { id: 999_999 }
      )
      result = service.send(:find_override)
      expect(result).to be_nil
    end

    it "returns nil for override with different set_type" do
      test_section = add_section("Test Section", course:)
      parent_section_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.create!(
        set_type: "CourseSection",
        set: test_section,
        title: "Section Override"
      )
      section_override = peer_review_sub_assignment.assignment_overrides.create!(
        set_type: "CourseSection",
        set: test_section,
        title: "Section Override",
        parent_override: parent_section_override
      )

      service = described_class.new(
        peer_review_sub_assignment:,
        override: { id: section_override.id }
      )
      result = service.send(:find_override)
      expect(result).to be_nil
    end
  end

  describe "integration with parent class methods" do
    let(:override_params) { { id: existing_override.id, set_type: "ADHOC", student_ids: [students[0].id] } }
    let(:service) do
      described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )
    end

    describe "#fetch_student_ids" do
      it "extracts the student_ids from the override params" do
        student_ids = service.send(:fetch_student_ids)
        expect(student_ids).to eq([students[0].id])
      end
    end

    describe "#override_title" do
      it "generates title based on student count" do
        title = service.send(:override_title, [students[0].id])
        expected_title = AssignmentOverride.title_from_student_count(1)
        expect(title).to eq(expected_title)
      end
    end
  end

  describe "parent override tracking" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let(:parent_override_students) { [students[0], students[1]] }
    let!(:parent_override) do
      parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
      parent_override_students.each do |student|
        parent_override.assignment_override_students.build(user: student)
      end
      parent_override.save!
      parent_override
    end

    let!(:test_existing_override) do
      override = peer_review_sub_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC, parent_override:)
      parent_override_students.each do |student|
        override.assignment_override_students.build(user: student)
      end
      override.save!
      override
    end

    context "when student list doesn't change" do
      let(:override_params) do
        {
          id: test_existing_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id, students[1].id],
          due_at: 2.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "keeps the same parent_override" do
        service.call
        test_existing_override.reload
        expect(test_existing_override.parent_override).to eq(parent_override)
      end
    end

    context "when student list changes" do
      let(:override_params) do
        {
          id: test_existing_override.id,
          set_type: "ADHOC",
          student_ids: [students[0].id, students[2].id]
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      context "when new parent override does not exist" do
        it "raises ParentOverrideNotFoundError" do
          expect { service.call }.to raise_error(
            PeerReview::ParentOverrideNotFoundError,
            /Parent assignment ADHOC override not found for students/
          )
        end
      end
    end

    context "when no student_ids provided in params" do
      let(:override_params) do
        {
          id: test_existing_override.id,
          set_type: "ADHOC",
          due_at: 2.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "validates the existing parent_override" do
        service.call
        test_existing_override.reload
        expect(test_existing_override.parent_override).to eq(parent_override)
      end
    end

    context "race condition protection" do
      let(:test_students) { create_users_in_course(course, 3, return_type: :record) }
      let(:test_parent_override) do
        parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        test_students.each do |student|
          parent_override.assignment_override_students.build(user: student)
        end
        parent_override.save!
        parent_override
      end

      let(:test_existing_override) do
        override = assignment_override_model(assignment: peer_review_sub_assignment, set_type: "ADHOC", parent_override_id: test_parent_override.id)
        test_students.each do |student|
          override.assignment_override_students.create!(user: student)
        end
        override
      end

      let(:override_params) do
        {
          id: test_existing_override.id,
          set_type: "ADHOC",
          student_ids: test_students.map(&:id),
          due_at: 3.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "validates parent override exists within transaction" do
        test_existing_override
        allow(service).to receive(:validate_adhoc_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_adhoc_parent_override_exists).once
      end

      it "uses a transaction to ensure atomicity of parent override lookup and update" do
        test_existing_override

        expect(ActiveRecord::Base).to receive(:transaction).and_call_original.at_least(:once)

        service.call
      end
    end
  end
end

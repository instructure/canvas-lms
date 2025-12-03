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

RSpec.describe PeerReview::AdhocOverrideCreatorService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:students) { create_users_in_course(course, 3, return_type: :record) }
  let(:non_course_student) { user_factory }
  let(:due_at) { 1.week.from_now }
  let(:unlock_at) { 1.day.from_now }
  let(:lock_at) { 2.weeks.from_now }
  let(:override_params) do
    {
      set_type: "ADHOC",
      student_ids: students.map(&:id),
      due_at:,
      unlock_at:,
      lock_at:,
      unassign_item: false
    }
  end

  let(:service) do
    described_class.new(
      peer_review_sub_assignment:,
      override: override_params
    )
  end

  def create_adhoc_override_for_parent_assignment(student_list)
    parent_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
    student_list.each do |student|
      parent_override.assignment_override_students.build(user: student)
    end
    parent_override.save!
    parent_override
  end

  describe "#initialize" do
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
      before do
        create_adhoc_override_for_parent_assignment(students)
      end

      it "creates an assignment override for the students" do
        expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
      end

      it "returns the created assignment override" do
        override = service.call
        expect(override).to be_an(AssignmentOverride)
        expect(override).to be_persisted
      end

      it "sets the correct set_type as ADHOC" do
        override = service.call
        expect(override.set_type).to eq(AssignmentOverride::SET_TYPE_ADHOC)
        expect(override.set_id).to be_nil
      end

      it "creates assignment_override_students for all valid student IDs" do
        override = service.call
        expect(override.assignment_override_students.count).to eq(3)
        expect(override.assignment_override_students.map(&:user_id)).to match_array(students.map(&:id))
      end

      it "applies the correct dates to the override" do
        override = service.call
        expect(override.due_at).to eq(due_at)
        expect(override.unlock_at).to eq(unlock_at)
        expect(override.lock_at).to eq(lock_at)
        expect(override.due_at_overridden).to be(true)
        expect(override.unlock_at_overridden).to be(true)
        expect(override.lock_at_overridden).to be(true)
      end

      it "sets the unassign_item property" do
        override = service.call
        expect(override.unassign_item).to be(false)
      end

      it "sets dont_touch_assignment to true" do
        override = service.call
        expect(override.dont_touch_assignment).to be(true)
      end

      it "sets the correct title based on student count" do
        override = service.call
        expected_title = AssignmentOverride.title_from_student_count(3)
        expect(override.title).to eq(expected_title)
      end

      it "wraps the operation in a transaction" do
        expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
        service.call
      end
    end

    context "with unassign_item set to true" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          student_ids: students.map(&:id),
          unassign_item: true
        }
      end

      before do
        create_adhoc_override_for_parent_assignment(students)
      end

      it "sets unassign_item to true on the override" do
        override = service.call
        expect(override.unassign_item).to be(true)
      end
    end

    context "with partial override dates" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          student_ids: students.map(&:id),
          due_at:
        }
      end

      before do
        create_adhoc_override_for_parent_assignment(students)
      end

      it "only applies the provided dates" do
        override = service.call
        expect(override.due_at).to eq(due_at)
        expect(override.unlock_at).to be_nil
        expect(override.lock_at).to be_nil
        expect(override.due_at_overridden).to be(true)
        expect(override.unlock_at_overridden).to be(false)
        expect(override.lock_at_overridden).to be(false)
      end
    end

    context "with mixed valid and invalid student IDs" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          student_ids: students.map(&:id) + [non_course_student.id, 999_999]
        }
      end

      before do
        create_adhoc_override_for_parent_assignment(students)
      end

      it "only creates override students for valid course students" do
        override = service.call
        expect(override.assignment_override_students.count).to eq(3)
        expect(override.assignment_override_students.map(&:user_id)).to match_array(students.map(&:id))
      end

      it "sets the title based on valid student count only" do
        override = service.call
        expected_title = AssignmentOverride.title_from_student_count(3)
        expect(override.title).to eq(expected_title)
      end
    end

    context "when student_ids is missing" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          due_at:
        }
      end

      it "raises StudentIdsRequiredError" do
        expect { service.call }.to raise_error(PeerReview::StudentIdsRequiredError, "Student ids are required")
      end
    end

    context "when student_ids is nil" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          student_ids: nil,
          due_at:
        }
      end

      it "raises StudentIdsRequiredError" do
        expect { service.call }.to raise_error(PeerReview::StudentIdsRequiredError, "Student ids are required")
      end
    end

    context "when student_ids is empty" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          student_ids: [],
          due_at:
        }
      end

      it "raises StudentIdsRequiredError" do
        expect { service.call }.to raise_error(PeerReview::StudentIdsRequiredError, "Student ids are required")
      end
    end

    context "when no valid student IDs exist in course" do
      let(:override_params) do
        {
          set_type: "ADHOC",
          student_ids: [non_course_student.id, 999_999]
        }
      end

      it "raises StudentIdsNotInCourseError" do
        expect { service.call }.to raise_error(PeerReview::StudentIdsNotInCourseError, "Student ids are not in course")
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_params) do
          {
            set_type: "ADHOC",
            student_ids: students.map(&:id),
            due_at: 1.day.from_now,
            unlock_at: 2.days.from_now
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be before unlock date")
        end
      end

      context "when due date is after lock date" do
        let(:override_params) do
          {
            set_type: "ADHOC",
            student_ids: students.map(&:id),
            due_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be after lock date")
        end
      end

      context "when unlock date is after lock date" do
        let(:override_params) do
          {
            set_type: "ADHOC",
            student_ids: students.map(&:id),
            unlock_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Unlock date cannot be after lock date")
        end
      end
    end

    context "transaction rollback scenarios" do
      before do
        create_adhoc_override_for_parent_assignment(students)
      end

      it "rolls back if save fails" do
        allow_any_instance_of(AssignmentOverride).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(AssignmentOverride.new))

        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
        expect(peer_review_sub_assignment.assignment_overrides.count).to eq(0)
      end

      it "rolls back if student validation fails mid-transaction" do
        course_students = double("course_students")
        allow(peer_review_sub_assignment.course).to receive(:all_students).and_return(course_students)
        allow(course_students).to receive(:where).and_raise(ActiveRecord::StatementInvalid.new("Database error"))

        expect { service.call }.to raise_error(ActiveRecord::StatementInvalid)
        expect(peer_review_sub_assignment.assignment_overrides.count).to eq(0)
      end
    end
  end

  describe "integration with parent class methods" do
    describe "#fetch_student_ids" do
      it "extracts the student_ids from the override params" do
        student_ids = service.send(:fetch_student_ids)
        expect(student_ids).to eq(students.map(&:id))
      end
    end

    describe "#fetch_unassign_item" do
      it "extracts the unassign_item from the override params" do
        unassign_item = service.send(:fetch_unassign_item)
        expect(unassign_item).to be(false)
      end

      context "when unassign_item is not provided" do
        let(:override_params) { { student_ids: students.map(&:id) } }

        it "defaults to false" do
          unassign_item = service.send(:fetch_unassign_item)
          expect(unassign_item).to be(false)
        end
      end
    end

    describe "#override_title" do
      it "generates title based on student count" do
        title = service.send(:override_title, students.map(&:id))
        expected_title = AssignmentOverride.title_from_student_count(3)
        expect(title).to eq(expected_title)
      end
    end
  end

  describe "parent override tracking" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let!(:parent_override) { create_adhoc_override_for_parent_assignment(students) }

    it "sets the parent_override on the created override" do
      override = service.call
      expect(override.parent_override).to eq(parent_override)
      expect(override.parent_override_id).to eq(parent_override.id)
    end

    it "finds the correct parent override based on student IDs" do
      override = service.call
      expect(override.parent_override.assignment_override_students.map(&:user_id).sort).to eq(students.map(&:id).sort)
    end

    context "when parent override does not exist" do
      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment ADHOC override not found for students/
        )
      end

      it "includes the student IDs in the error message" do
        service.call
      rescue PeerReview::ParentOverrideNotFoundError => e
        students.each do |student|
          expect(e.message).to include(student.id.to_s)
        end
      end
    end

    context "when parent override exists but for different students" do
      let(:other_students) { create_users_in_course(course, 2, return_type: :record) }
      let(:different_parent_override) { create_adhoc_override_for_parent_assignment(other_students) }

      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment ADHOC override not found for students/
        )
      end
    end

    context "when parent override matches subset of students" do
      let(:override_params_subset) do
        {
          set_type: "ADHOC",
          student_ids: students.map(&:id),
          due_at:,
          unlock_at:,
          lock_at:,
          unassign_item: false
        }
      end

      let(:service_subset) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params_subset
        )
      end

      before do
        parent_override.assignment_override_students.last.destroy
      end

      it "raises ParentOverrideNotFoundError because student lists don't match exactly" do
        expect { service_subset.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment ADHOC override not found for students/
        )
      end
    end

    context "transaction protection for parent override lookup" do
      it "validates parent override exists within transaction" do
        allow(service).to receive(:validate_adhoc_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_adhoc_parent_override_exists).once
      end

      it "uses a transaction to ensure atomicity of parent override lookup and creation" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original.at_least(:once)

        service.call
      end

      it "rolls back if parent override validation fails during transaction" do
        allow(service).to receive(:validate_adhoc_parent_override_exists).and_raise(PeerReview::ParentOverrideNotFoundError, "Test error")

        expect { service.call }.to raise_error(PeerReview::ParentOverrideNotFoundError)
        expect(peer_review_sub_assignment.assignment_overrides.count).to eq(0)
      end

      it "finds parent override inside the transaction block" do
        find_parent_called_in_transaction = false

        allow(service).to receive(:find_parent_override).and_wrap_original do |method, *args|
          find_parent_called_in_transaction = ActiveRecord::Base.connection.transaction_open?
          method.call(*args)
        end

        service.call

        expect(find_parent_called_in_transaction).to be true
      end
    end
  end
end

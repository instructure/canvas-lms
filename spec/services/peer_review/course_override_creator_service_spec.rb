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

RSpec.describe PeerReview::CourseOverrideCreatorService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:due_at) { 1.week.from_now }
  let(:unlock_at) { 1.day.from_now }
  let(:lock_at) { 2.weeks.from_now }
  let(:override_params) do
    {
      set_type: "Course",
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

  describe "#initialize" do
    it "inherits from PeerReview::CourseOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::CourseOverrideCommonService)
    end

    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_params)
    end
  end

  describe "#call" do
    context "with valid parameters" do
      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: course)
      end

      it "creates course override for the peer review sub assignment" do
        expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
      end

      it "returns the created override" do
        override = service.call
        expect(override).to be_an(AssignmentOverride)
        expect(override).to be_persisted
      end

      it "sets the correct course on the override" do
        override = service.call
        expect(override.set).to eq(course)
        expect(override.set_type).to eq(AssignmentOverride::SET_TYPE_COURSE)
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

      it "sets dont_touch_assignment to true" do
        override = service.call
        expect(override.dont_touch_assignment).to be(true)
      end
    end

    context "with partial override dates" do
      let(:override_params) do
        {
          set_type: "Course",
          due_at:
        }
      end

      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: course)
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

    context "with no dates provided" do
      let(:override_params) do
        {
          set_type: "Course"
        }
      end

      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: course)
      end

      it "creates an override without any dates" do
        override = service.call
        expect(override).to be_persisted
        expect(override.due_at).to be_nil
        expect(override.unlock_at).to be_nil
        expect(override.lock_at).to be_nil
        expect(override.due_at_overridden).to be(false)
        expect(override.unlock_at_overridden).to be(false)
        expect(override.lock_at_overridden).to be(false)
      end
    end

    context "when peer review sub assignment has no course" do
      let(:peer_review_sub_assignment_without_course) do
        peer_review_sub = peer_review_model(course:)
        allow(peer_review_sub).to receive(:course).and_return(nil)
        peer_review_sub
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment: peer_review_sub_assignment_without_course,
          override: override_params
        )
      end

      it "raises CourseNotFoundError" do
        expect { service.call }.to raise_error(PeerReview::CourseNotFoundError, "Course does not exist")
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_params) do
          {
            set_type: "Course",
            due_at: 1.day.from_now,
            unlock_at: 2.days.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidDatesError, "Due date cannot be before unlock date")
        end
      end

      context "when due date is after lock date" do
        let(:override_params) do
          {
            set_type: "Course",
            due_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidDatesError, "Due date cannot be after lock date")
        end
      end

      context "when unlock date is after lock date" do
        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidDatesError, "Unlock date cannot be after lock date")
        end
      end
    end

    context "validation against parent override dates" do
      let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }

      context "when peer review dates fall within parent override dates" do
        let!(:parent_override) do
          assignment_override_model(
            assignment: parent_assignment,
            set: course,
            unlock_at: 1.day.from_now,
            lock_at: 3.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 2.weeks.from_now
          }
        end

        it "creates the override successfully" do
          parent_override
          expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
        end
      end

      context "when peer review unlock_at is before parent unlock_at" do
        let!(:parent_override) do
          assignment_override_model(
            assignment: parent_assignment,
            set: course,
            unlock_at: 2.days.from_now,
            lock_at: 3.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 1.day.from_now,
            due_at: 1.week.from_now,
            lock_at: 2.weeks.from_now
          }
        end

        it "raises InvalidDatesError" do
          parent_override
          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end
      end

      context "when peer review due_at is after parent lock_at" do
        let!(:parent_override) do
          assignment_override_model(
            assignment: parent_assignment,
            set: course,
            unlock_at: 1.day.from_now,
            lock_at: 2.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 2.days.from_now,
            due_at: 3.weeks.from_now,
            lock_at: 4.weeks.from_now
          }
        end

        it "raises InvalidDatesError" do
          parent_override
          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override due date cannot be after parent override lock date/
          )
        end
      end

      context "when peer review lock_at is after parent lock_at" do
        let!(:parent_override) do
          assignment_override_model(
            assignment: parent_assignment,
            set: course,
            unlock_at: 1.day.from_now,
            lock_at: 2.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 3.weeks.from_now
          }
        end

        it "raises InvalidDatesError" do
          parent_override
          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end
      end

      context "when parent override has no unlock_at" do
        let!(:parent_override) do
          assignment_override_model(
            assignment: parent_assignment,
            set: course,
            lock_at: 2.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 1.day.ago,
            due_at: 1.week.from_now,
            lock_at: 10.days.from_now
          }
        end

        it "does not validate against parent unlock_at" do
          parent_override
          expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
        end
      end

      context "when parent override has no lock_at" do
        let!(:parent_override) do
          assignment_override_model(
            assignment: parent_assignment,
            set: course,
            unlock_at: 1.day.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Course",
            unlock_at: 2.days.from_now,
            due_at: 1.month.from_now,
            lock_at: 2.months.from_now
          }
        end

        it "does not validate against parent lock_at" do
          parent_override
          expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
        end
      end
    end
  end

  describe "integration with parent class methods" do
    describe "#fetch_id" do
      let(:override_params_with_id) do
        override_params.merge(id: 789)
      end

      let(:service_with_id) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params_with_id
        )
      end

      it "extracts the id from the override params" do
        id = service_with_id.send(:fetch_id)
        expect(id).to eq(789)
      end
    end
  end

  describe "parent override tracking" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let!(:parent_override) do
      assignment_override_model(assignment: parent_assignment, set: course)
    end

    it "sets the parent_override on the created override" do
      override = service.call
      expect(override.parent_override).to eq(parent_override)
      expect(override.parent_override_id).to eq(parent_override.id)
    end

    it "finds the correct parent override based on course ID" do
      override = service.call
      expect(override.parent_override.set).to eq(course)
      expect(override.parent_override.set_type).to eq(AssignmentOverride::SET_TYPE_COURSE)
    end

    context "when parent override does not exist" do
      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment Course override not found for course [\d,]+/
        )
      end
    end

    context "when parent override exists for different course" do
      let(:other_course) { course_model(name: "Other Course") }
      let(:other_parent_override) do
        other_assignment = other_course.assignments.create!
        assignment_override_model(assignment: other_assignment, set: other_course)
      end

      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment Course override not found for course [\d,]+/
        )
      end
    end

    it "wraps the operation in a transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
      service.call
    end

    context "transaction protection for parent override lookup" do
      it "validates parent override exists within transaction" do
        allow(service).to receive(:validate_course_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_course_parent_override_exists).once
      end

      it "rolls back if parent override validation fails during transaction" do
        allow(service).to receive(:validate_course_parent_override_exists).and_raise(PeerReview::ParentOverrideNotFoundError, "Test error")

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

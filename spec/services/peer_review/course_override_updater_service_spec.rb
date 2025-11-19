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

RSpec.describe PeerReview::CourseOverrideUpdaterService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:existing_due_at) { 1.week.from_now }
  let(:existing_unlock_at) { 1.day.from_now }
  let(:existing_lock_at) { 2.weeks.from_now }
  let(:updated_due_at) { 2.weeks.from_now }
  let(:updated_unlock_at) { 2.days.from_now }
  let(:updated_lock_at) { 3.weeks.from_now }

  let(:parent_override) do
    assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: course)
  end

  let!(:existing_override) do
    assignment_override_model(assignment: peer_review_sub_assignment, set: course, due_at: existing_due_at, lock_at: existing_lock_at, unlock_at: existing_unlock_at, parent_override:)
  end

  let(:override_data) do
    {
      id: existing_override.id,
      set_type: "Course",
      due_at: updated_due_at,
      lock_at: updated_lock_at,
      unlock_at: updated_unlock_at
    }
  end

  let(:service) do
    described_class.new(
      peer_review_sub_assignment:,
      override: override_data
    )
  end

  before do
    course.enable_feature!(:peer_review_allocation_and_grading)
  end

  describe "#initialize" do
    it "inherits from PeerReview::CourseOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::CourseOverrideCommonService)
    end

    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_data)
    end
  end

  describe "#call" do
    context "when override exists and validations pass" do
      it "updates the existing override" do
        result = service.call

        expect(result).to eq(existing_override)
        expect(result.due_at).to eq(override_data[:due_at])
        expect(result.lock_at).to eq(override_data[:lock_at])
        expect(result.unlock_at).to eq(override_data[:unlock_at])
      end

      it "persists the changes to the database" do
        service.call
        existing_override.reload

        expect(existing_override.due_at).to eq(updated_due_at)
        expect(existing_override.lock_at).to eq(updated_lock_at)
        expect(existing_override.unlock_at).to eq(updated_unlock_at)
      end

      it "maintains the course association" do
        service.call
        existing_override.reload

        expect(existing_override.set).to eq(course)
        expect(existing_override.set_type).to eq(AssignmentOverride::SET_TYPE_COURSE)
      end
    end

    context "with partial date updates" do
      let(:override_data) do
        {
          id: existing_override.id,
          set_type: "Course",
          due_at: updated_due_at
        }
      end

      it "only updates the provided dates" do
        service.call
        existing_override.reload

        expect(existing_override.due_at).to eq(updated_due_at)
        expect(existing_override.unlock_at).to eq(existing_unlock_at)
        expect(existing_override.lock_at).to eq(existing_lock_at)
      end
    end

    context "when validations fail" do
      it "raises error for invalid override dates" do
        invalid_dates = override_data.merge(
          due_at: 1.day.from_now,
          unlock_at: 3.days.from_now
        )
        invalid_service = described_class.new(
          peer_review_sub_assignment:,
          override: invalid_dates
        )

        expect { invalid_service.call }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Due date cannot be before unlock date"
        )
      end

      it "raises error when override doesn't exist" do
        non_existent_override = override_data.merge(id: 99_999)
        service_with_non_existent = described_class.new(
          peer_review_sub_assignment:,
          override: non_existent_override
        )

        expect { service_with_non_existent.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end

      it "raises error when override is for wrong set_type" do
        section = add_section("Test Section", course:)
        parent_section_override = peer_review_sub_assignment.parent_assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set: section,
          dont_touch_assignment: true
        )
        section_override = peer_review_sub_assignment.assignment_overrides.create!(
          set: section,
          due_at: existing_due_at,
          parent_override: parent_section_override
        )

        wrong_type_data = override_data.merge(id: section_override.id)
        wrong_type_service = described_class.new(
          peer_review_sub_assignment:,
          override: wrong_type_data
        )

        expect { wrong_type_service.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end

      it "raises error when course does not exist" do
        allow(peer_review_sub_assignment).to receive(:course).and_return(nil)

        expect { service.call }.to raise_error(
          PeerReview::CourseNotFoundError,
          "Course does not exist"
        )
      end
    end

    context "when id is missing" do
      let(:override_data) do
        {
          set_type: "Course",
          due_at: updated_due_at
        }
      end

      it "raises error when override cannot be found" do
        expect { service.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end
    end

    context "with multiple course overrides" do
      let(:other_peer_review) { peer_review_model(course:) }
      let!(:other_parent_override) do
        assignment_override_model(assignment: other_peer_review.parent_assignment, set: course)
      end
      let!(:other_override) do
        assignment_override_model(assignment: other_peer_review, set: course, due_at: existing_due_at, parent_override: other_parent_override)
      end

      it "only updates the correct override" do
        service.call
        existing_override.reload
        other_override.reload

        expect(existing_override.due_at).to eq(updated_due_at)
        expect(other_override.due_at).to eq(existing_due_at)
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_data) do
          {
            id: existing_override.id,
            set_type: "Course",
            due_at: 1.day.from_now,
            unlock_at: 2.days.from_now
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be before unlock date")
        end
      end

      context "when due date is after lock date" do
        let(:override_data) do
          {
            id: existing_override.id,
            set_type: "Course",
            due_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be after lock date")
        end
      end

      context "when unlock date is after lock date" do
        let(:override_data) do
          {
            id: existing_override.id,
            set_type: "Course",
            unlock_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Unlock date cannot be after lock date")
        end
      end
    end
  end

  describe "parent override tracking" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let!(:parent_override) do
      assignment_override_model(assignment: parent_assignment, set: course)
    end

    before do
      existing_override.update!(parent_override:)
    end

    it "validates parent_override exists during update" do
      service.call
      existing_override.reload
      expect(existing_override.parent_override).to eq(parent_override)
    end

    context "when parent override is deleted" do
      before do
        parent_override.destroy
      end

      it "raises OverrideNotFoundError when parent is deleted" do
        expect { service.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end
    end

    it "maintains the same parent_override reference on update" do
      result = service.call
      expect(result.parent_override).to eq(parent_override)
      expect(result.parent_override_id).to eq(parent_override.id)
    end

    it "wraps the operation in a transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
      service.call
    end

    context "race condition protection" do
      it "validates parent override within transaction" do
        allow(service).to receive(:validate_course_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_course_parent_override_exists).with(parent_override, course.id).once
      end

      it "uses a transaction to ensure atomicity of parent override lookup and update" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original.at_least(:once)

        service.call
      end
    end
  end
end

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

RSpec.describe PeerReview::SectionOverrideUpdaterService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:section1) { add_section("Section 1", course:) }
  let(:section2) { add_section("Section 2", course:) }
  let(:due_hour) { 9 } # Set time to avoid potential issues with end-of-day boundaries that could cause intermittent test failures
  let(:existing_due_at) { 1.week.from_now.change(hour: due_hour) }
  let(:existing_unlock_at) { 1.day.from_now.change(hour: due_hour) }
  let(:existing_lock_at) { 2.weeks.from_now.change(hour: due_hour) }
  let(:updated_due_at) { 2.weeks.from_now.change(hour: due_hour) }
  let(:updated_unlock_at) { 2.days.from_now.change(hour: due_hour) }
  let(:updated_lock_at) { 3.weeks.from_now.change(hour: due_hour) }

  let(:parent_override1) do
    assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section1)
  end

  let(:existing_override) do
    assignment_override_model(assignment: peer_review_sub_assignment, set: section1, due_at: existing_due_at, lock_at: existing_lock_at, unlock_at: existing_unlock_at, unassign_item: false, parent_override: parent_override1)
  end

  let(:parent_override2) do
    assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section2)
  end

  let(:override_data) do
    {
      id: existing_override.id,
      set_id: section2.id,
      set_type: "CourseSection",
      due_at: updated_due_at,
      lock_at: updated_lock_at,
      unlock_at: updated_unlock_at,
      unassign_item: true
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
    it "inherits from PeerReview::SectionOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::SectionOverrideCommonService)
    end

    it "sets peer_review_sub_assignment and override instance variables" do
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_data)
    end
  end

  describe "#call" do
    before do
      existing_override
      parent_override2
    end

    context "when override exists and validations pass" do
      it "updates the existing override" do
        result = service.call

        expect(result).to eq(existing_override)
        expect(result.due_at).to eq(override_data[:due_at])
        expect(result.lock_at).to eq(override_data[:lock_at])
        expect(result.unlock_at).to eq(override_data[:unlock_at])
      end

      it "updates the section association" do
        service.call
        existing_override.reload

        expect(existing_override.set).to eq(section2)
        expect(existing_override.set_id).to eq(section2.id)
      end
    end

    context "when validations fail" do
      it "raises error for invalid override dates" do
        invalid_dates = override_data.merge(
          due_at: 1.day.from_now.change(hour: due_hour),
          unlock_at: 3.days.from_now.change(hour: due_hour)
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

      it "raises error when section doesn't exist" do
        invalid_section_data = override_data.merge(set_id: 99_999)
        invalid_service = described_class.new(
          peer_review_sub_assignment:,
          override: invalid_section_data
        )

        expect { invalid_service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "uses existing override set_id when set_id is missing" do
        no_set_id_data = override_data.except(:set_id)
        no_set_id_service = described_class.new(
          peer_review_sub_assignment:,
          override: no_set_id_data
        )

        result = no_set_id_service.call
        expect(result.set_id).to eq(existing_override.set_id)
      end
    end

    context "when section doesn't change" do
      let(:same_section_override_data) do
        {
          id: existing_override.id,
          set_id: section1.id,
          set_type: "CourseSection",
          due_at: updated_due_at,
          lock_at: updated_lock_at,
          unlock_at: updated_unlock_at,
          unassign_item: true
        }
      end

      let(:same_section_service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: same_section_override_data
        )
      end

      it "still updates dates without changing section" do
        result = same_section_service.call
        existing_override.reload

        expect(result.set).to eq(section1)
        expect(result.set_id).to eq(section1.id)
        expect(result.due_at).to eq(updated_due_at)
        expect(result.lock_at).to eq(updated_lock_at)
        expect(result.unlock_at).to eq(updated_unlock_at)
      end
    end
  end

  describe "integration with ApplicationService" do
    before do
      existing_override
      parent_override2
    end

    it "can be called via the class method" do
      result = described_class.call(peer_review_sub_assignment:, override: override_data)
      expect(result).to be_a(AssignmentOverride)
      expect(result).to eq(existing_override)
    end
  end

  describe "parent override tracking" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let!(:parent_override_section1) do
      assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section1)
    end
    let!(:parent_override_section2) do
      assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section2)
    end

    let!(:tracking_existing_override) do
      assignment_override_model(assignment: peer_review_sub_assignment, set: section1, due_at: existing_due_at, lock_at: existing_lock_at, unlock_at: existing_unlock_at, unassign_item: false, parent_override: parent_override_section1)
    end

    let(:tracking_override_data) do
      {
        id: tracking_existing_override.id,
        set_id: section2.id,
        set_type: "CourseSection",
        due_at: updated_due_at,
        lock_at: updated_lock_at,
        unlock_at: updated_unlock_at,
        unassign_item: true
      }
    end

    let(:tracking_service) do
      described_class.new(
        peer_review_sub_assignment:,
        override: tracking_override_data
      )
    end

    context "when section doesn't change" do
      let(:same_section_override_data) do
        {
          id: tracking_existing_override.id,
          set_id: section1.id,
          set_type: "CourseSection",
          due_at: updated_due_at
        }
      end

      let(:same_section_service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: same_section_override_data
        )
      end

      it "keeps the same parent_override" do
        same_section_service.call
        tracking_existing_override.reload
        expect(tracking_existing_override.parent_override).to eq(parent_override_section1)
      end

      it "validates parent_override still exists" do
        parent_override_section1.destroy
        expect { same_section_service.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end
    end

    context "when section changes" do
      it "updates to the new parent_override" do
        tracking_service.call
        tracking_existing_override.reload
        expect(tracking_existing_override.parent_override).to eq(parent_override_section2)
        expect(tracking_existing_override.parent_override_id).to eq(parent_override_section2.id)
      end

      it "finds parent override based on new section ID" do
        tracking_service.call
        tracking_existing_override.reload
        expect(tracking_existing_override.parent_override.set).to eq(section2)
        expect(tracking_existing_override.parent_override.set_type).to eq(AssignmentOverride::SET_TYPE_COURSE_SECTION)
      end

      context "when new parent override does not exist" do
        before do
          parent_override_section2.destroy
        end

        it "raises ParentOverrideNotFoundError" do
          expect { tracking_service.call }.to raise_error(
            PeerReview::ParentOverrideNotFoundError,
            /Parent assignment Section override not found for section [\d,]+/
          )
        end
      end
    end

    it "wraps the operation in a transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
      tracking_service.call
    end

    context "race condition protection" do
      it "validates parent override within transaction" do
        allow(tracking_service).to receive(:validate_section_parent_override_exists).and_call_original

        tracking_service.call

        expect(tracking_service).to have_received(:validate_section_parent_override_exists).once
      end

      it "uses a transaction to ensure atomicity of parent override lookup and update" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original.at_least(:once)

        tracking_service.call
      end
    end
  end
end

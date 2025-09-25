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

RSpec.describe PeerReview::SectionOverrideCommonService do
  let(:override_params) do
    {
      set_id: 123,
      set_type: "CourseSection",
      due_at: 2.days.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 3.days.from_now,
      unassign_item: false
    }
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      service = described_class.new(
        peer_review_sub_assignment: nil,
        override: override_params
      )

      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@override)).to eq(override_params)
    end

    it "allows nil values for both parameters" do
      service = described_class.new
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@override)).to eq({})
    end
  end

  describe "#fetch_set_id" do
    let(:service) { described_class.new(override: override_params) }

    it "returns the set_id value from the override" do
      expect(service.send(:fetch_set_id)).to eq(123)
    end

    context "when override contains set_id as nil" do
      let(:override_with_nil) { override_params.merge(set_id: nil) }
      let(:service_with_nil) { described_class.new(override: override_with_nil) }

      it "returns nil" do
        expect(service_with_nil.send(:fetch_set_id)).to be_nil
      end
    end

    context "when override does not contain set_id" do
      let(:override_without_set_id) { override_params.except(:set_id) }
      let(:service_without_set_id) { described_class.new(override: override_without_set_id) }

      it "returns nil" do
        expect(service_without_set_id.send(:fetch_set_id)).to be_nil
      end
    end

    context "when override is nil" do
      let(:service_without_override) { described_class.new }

      it "returns nil when key is not found" do
        expect(service_without_override.send(:fetch_set_id)).to be_nil
      end
    end
  end

  describe "#fetch_unassign_item" do
    let(:service) { described_class.new(override: override_params) }

    it "returns the unassign_item value" do
      expect(service.send(:fetch_unassign_item)).to be override_params[:unassign_item]
    end

    context "when override does not contain unassign_item" do
      let(:override_without_unassign) { override_params.except(:unassign_item) }
      let(:service_without_unassign) { described_class.new(override: override_without_unassign) }

      it "returns false as default" do
        expect(service_without_unassign.send(:fetch_unassign_item)).to be false
      end
    end
  end

  describe "module inclusion" do
    it "includes PeerReview::Validations module" do
      expect(described_class.included_modules).to include(PeerReview::Validations)
    end

    it "includes PeerReview::DateOverrider module" do
      expect(described_class.included_modules).to include(PeerReview::DateOverrider)
    end

    it "responds to validation methods from PeerReview::Validations" do
      service = described_class.new
      expect(service).to respond_to(:validate_parent_assignment)
      expect(service).to respond_to(:validate_peer_reviews_enabled)
      expect(service).to respond_to(:validate_feature_enabled)
      expect(service).to respond_to(:validate_override_dates)
    end

    it "responds to date override methods from PeerReview::DateOverrider" do
      service = described_class.new
      expect(service).to respond_to(:apply_overridden_dates)
    end
  end

  describe "integration with ApplicationService" do
    it "inherits from ApplicationService" do
      expect(described_class.superclass).to eq(ApplicationService)
    end

    it "responds to the call class method" do
      expect(described_class).to respond_to(:call)
    end
  end

  describe "#course_section" do
    let(:course) { course_model(name: "Test Course") }
    let(:section) { add_section("Test Section", course:) }
    let(:peer_review_sub_assignment) { double("PeerReviewSubAssignment", course:) }
    let(:service_with_peer_review) do
      described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )
    end

    it "returns the correct section when valid section_id is provided" do
      result = service_with_peer_review.send(:course_section, section.id)
      expect(result).to eq(section)
    end

    context "when peer_review_sub_assignment is nil" do
      let(:service_without_peer_review) { described_class.new(override: override_params) }

      it "returns nil" do
        result = service_without_peer_review.send(:course_section, 123)
        expect(result).to be_nil
      end
    end

    context "when course is nil" do
      let(:peer_review_sub_assignment_without_course) { double("PeerReviewSubAssignment", course: nil) }
      let(:service_with_nil_course) do
        described_class.new(
          peer_review_sub_assignment: peer_review_sub_assignment_without_course,
          override: override_params
        )
      end

      it "returns nil" do
        result = service_with_nil_course.send(:course_section, 123)
        expect(result).to be_nil
      end
    end

    context "when active_course_sections is nil" do
      let(:course_without_sections) { double("Course", active_course_sections: nil) }
      let(:peer_review_sub_assignment_without_sections) { double("PeerReviewSubAssignment", course: course_without_sections) }
      let(:service_with_nil_sections) do
        described_class.new(
          peer_review_sub_assignment: peer_review_sub_assignment_without_sections,
          override: override_params
        )
      end

      it "returns nil" do
        result = service_with_nil_sections.send(:course_section, 123)
        expect(result).to be_nil
      end
    end
  end

  describe "edge cases" do
    context "when override contains unexpected keys" do
      let(:override_with_extras) do
        override_params.merge(
          extra_key: "unexpected",
          another_key: 123
        )
      end

      let(:service_with_extras) { described_class.new(override: override_with_extras) }

      it "extracts known keys correctly" do
        expect(service_with_extras.send(:fetch_set_id)).to eq(123)
        expect(service_with_extras.send(:fetch_unassign_item)).to be false
      end
    end
  end
end

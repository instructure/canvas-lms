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

RSpec.describe PeerReview::CourseOverrideCommonService do
  let(:override_params) do
    {
      id: 456,
      set_type: "Course",
      due_at: 2.days.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 3.days.from_now
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

  describe "#fetch_id" do
    let(:service) { described_class.new(override: override_params) }

    it "returns the id value from the override" do
      expect(service.send(:fetch_id)).to eq(456)
    end

    context "when override contains id as nil" do
      let(:override_with_nil) { override_params.merge(id: nil) }
      let(:service_with_nil) { described_class.new(override: override_with_nil) }

      it "returns nil" do
        expect(service_with_nil.send(:fetch_id)).to be_nil
      end
    end

    context "when override does not contain id" do
      let(:override_without_id) { override_params.except(:id) }
      let(:service_without_id) { described_class.new(override: override_without_id) }

      it "returns nil" do
        expect(service_without_id.send(:fetch_id)).to be_nil
      end
    end

    context "when override is nil" do
      let(:service_without_override) { described_class.new }

      it "returns nil when key is not found" do
        expect(service_without_override.send(:fetch_id)).to be_nil
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
      expect(service).to respond_to(:validate_peer_review_dates)
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
        expect(service_with_extras.send(:fetch_id)).to eq(456)
      end
    end
  end

  describe "#find_parent_override" do
    let(:course) { course_model(name: "Test Course") }
    let(:peer_review_sub_assignment) { peer_review_model(course:) }
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    context "when parent override exists with matching course ID" do
      let!(:parent_override) do
        assignment_override_model(assignment: parent_assignment, set: course)
      end

      it "finds the parent override based on course ID" do
        result = service.send(:find_parent_override, course.id)
        expect(result).to eq(parent_override)
      end

      it "returns an AssignmentOverride instance" do
        result = service.send(:find_parent_override, course.id)
        expect(result).to be_a(AssignmentOverride)
      end

      it "returns override with correct set_type" do
        result = service.send(:find_parent_override, course.id)
        expect(result.set_type).to eq(AssignmentOverride::SET_TYPE_COURSE)
      end
    end

    context "when parent override does not exist" do
      it "returns nil" do
        result = service.send(:find_parent_override, course.id)
        expect(result).to be_nil
      end
    end

    context "when parent override is deleted" do
      let(:parent_override) do
        override = assignment_override_model(assignment: parent_assignment, set: course)
        override.destroy
        override
      end

      it "returns nil for deleted override" do
        result = service.send(:find_parent_override, course.id)
        expect(result).to be_nil
      end
    end
  end

  describe "#parent_assignment" do
    let(:course) { course_model(name: "Test Course") }
    let(:peer_review_sub_assignment) { peer_review_model(course:) }
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    it "returns the parent assignment of the peer review sub assignment" do
      result = service.send(:parent_assignment)
      expect(result).to eq(peer_review_sub_assignment.parent_assignment)
    end

    it "returns an Assignment instance" do
      result = service.send(:parent_assignment)
      expect(result).to be_a(Assignment)
    end
  end
end

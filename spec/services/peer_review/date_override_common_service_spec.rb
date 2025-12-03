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

RSpec.describe PeerReview::DateOverrideCommonService do
  let(:course) { course_model(name: "Course with Assignment") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:section1) { add_section("Section 1", course:) }
  let(:section2) { add_section("Section 2", course:) }

  let!(:parent_section_override) do
    assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section1)
  end

  let!(:existing_section_override) do
    assignment_override_model(assignment: peer_review_sub_assignment, set: section1, parent_override: parent_section_override)
  end

  before do
    course.enable_feature!(:peer_review_grading)
  end

  describe "#initialize" do
    it "inherits from ApplicationService" do
      expect(described_class.superclass).to eq(ApplicationService)
    end

    it "includes PeerReview::Validations" do
      expect(described_class.included_modules).to include(PeerReview::Validations)
    end

    it "sets peer_review_sub_assignment and overrides instance variables" do
      overrides = [{ id: 1, set_type: "CourseSection" }]
      service = described_class.new(
        peer_review_sub_assignment:,
        overrides:
      )

      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@overrides)).to eq(overrides)
    end

    it "can be initialized with nil values" do
      service = described_class.new
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@overrides)).to eq([])
    end
  end

  describe "#call" do
    context "when services hash is empty" do
      let(:override_data) do
        [{
          id: existing_section_override.id,
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: override_data
        )
      end

      it "raises error for unsupported set_type" do
        expect { service.call }.to raise_error(
          PeerReview::SetTypeNotSupportedError,
          "Set type 'CourseSection' is not supported. Supported types are: "
        )
      end
    end

    context "with mocked services" do
      let(:mock_section_service) { instance_double("MockSectionService") }

      let(:override_data) do
        [{
          id: existing_section_override.id,
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: override_data
        )
      end

      before do
        allow(service).to receive(:services).and_return({
                                                          AssignmentOverride::SET_TYPE_COURSE_SECTION => mock_section_service
                                                        })
      end

      it "calls the appropriate service for each override" do
        expect(mock_section_service).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[0]
        )

        service.call
      end

      it "processes multiple overrides of the same type" do
        parent_section2_override = assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section2)
        second_section_override = assignment_override_model(assignment: peer_review_sub_assignment, set: section2, parent_override: parent_section2_override)

        duplicate_section_data = [
          override_data[0],
          {
            id: second_section_override.id,
            due_at: 4.weeks.from_now
          }
        ]

        duplicate_service = described_class.new(
          peer_review_sub_assignment:,
          overrides: duplicate_section_data
        )
        allow(duplicate_service).to receive(:services).and_return({
                                                                    AssignmentOverride::SET_TYPE_COURSE_SECTION => mock_section_service
                                                                  })

        expect(mock_section_service).to receive(:call).twice

        duplicate_service.call
      end
    end

    context "when set_type is missing but override exists" do
      let(:override_without_set_type) do
        [{
          id: existing_section_override.id,
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: override_without_set_type
        )
      end

      let(:mock_service) { instance_double("MockService") }

      before do
        allow(service).to receive(:services).and_return({
                                                          AssignmentOverride::SET_TYPE_COURSE_SECTION => mock_service
                                                        })
      end

      it "looks up set_type from preloaded existing overrides" do
        expect(mock_service).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_without_set_type[0]
        )

        service.call
      end

      it "preloads existing overrides before processing" do
        expect(service).to receive(:preload_existing_overrides).and_call_original
        allow(mock_service).to receive(:call)

        service.call
      end
    end

    context "when validations fail" do
      it "raises error when set_type is missing and no id provided" do
        invalid_override = [{ due_at: 2.weeks.from_now }]
        service = described_class.new(
          peer_review_sub_assignment:,
          overrides: invalid_override
        )

        expect { service.call }.to raise_error(
          PeerReview::SetTypeRequiredError,
          "Set type is required"
        )
      end

      it "raises error when override with id doesn't exist" do
        non_existent_override = [{
          id: 99_999,
          due_at: 2.weeks.from_now
        }]
        service = described_class.new(
          peer_review_sub_assignment:,
          overrides: non_existent_override
        )

        expect { service.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end

      it "raises error when set_type is not supported" do
        unsupported_override = [{
          id: existing_section_override.id,
          set_type: "UnsupportedType",
          due_at: 2.weeks.from_now
        }]
        service = described_class.new(
          peer_review_sub_assignment:,
          overrides: unsupported_override
        )

        expect { service.call }.to raise_error(
          PeerReview::SetTypeNotSupportedError,
          "Set type 'UnsupportedType' is not supported. Supported types are: "
        )
      end
    end

    context "with empty overrides array" do
      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: []
        )
      end

      it "processes successfully with no overrides" do
        expect { service.call }.not_to raise_error
      end

      it "does not call preload_existing_overrides when no overrides" do
        expect(service.send(:preload_existing_overrides)).to be_nil
      end
    end
  end

  describe "#preload_existing_overrides" do
    let(:service) do
      described_class.new(
        peer_review_sub_assignment:,
        overrides: override_data
      )
    end

    context "when overrides array is empty" do
      let(:override_data) { [] }

      it "returns nil without querying database" do
        expect(peer_review_sub_assignment.assignment_overrides).not_to receive(:active)
        result = service.send(:preload_existing_overrides)
        expect(result).to be_nil
      end
    end

    context "when no overrides have existing ids" do
      let(:override_data) do
        [
          { set_type: "CourseSection", set_id: section1.id },
          { set_type: "CourseSection", set_id: section2.id }
        ]
      end

      it "returns nil without querying database" do
        expect(peer_review_sub_assignment.assignment_overrides).not_to receive(:active)
        result = service.send(:preload_existing_overrides)
        expect(result).to be_nil
      end
    end

    context "when overrides have existing ids" do
      let(:parent_section2_override) do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section2)
      end

      let(:second_override) do
        assignment_override_model(assignment: peer_review_sub_assignment, set: section2, parent_override: parent_section2_override)
      end

      let(:override_data) do
        [
          { id: existing_section_override.id, due_at: 1.week.from_now },
          { id: second_override.id, due_at: 2.weeks.from_now },
          { set_type: "CourseSection", set_id: section1.id }
        ]
      end

      before do
        second_override # ensure it's created
      end

      it "returns hash of existing overrides indexed by id" do
        result = service.send(:preload_existing_overrides)

        expect(result).to be_a(Hash)
        expect(result.keys).to contain_exactly(existing_section_override.id, second_override.id)
        expect(result[existing_section_override.id]).to eq(existing_section_override)
        expect(result[second_override.id]).to eq(second_override)
      end

      it "queries for overrides with provided ids" do
        # Test that the method attempts to query with the correct ids
        result = service.send(:preload_existing_overrides)

        # Verify that we get the expected overrides back
        expect(result.keys).to contain_exactly(existing_section_override.id, second_override.id)
      end

      it "filters out soft-deleted overrides" do
        second_override.destroy

        result = service.send(:preload_existing_overrides)

        expect(result.keys).to contain_exactly(existing_section_override.id)
        expect(result[second_override.id]).to be_nil
      end
    end

    context "when some ids don't exist" do
      let(:override_data) do
        [
          { id: existing_section_override.id, due_at: 1.week.from_now },
          { id: 99_999, due_at: 2.weeks.from_now }
        ]
      end

      it "only includes existing overrides in result" do
        result = service.send(:preload_existing_overrides)

        expect(result.keys).to contain_exactly(existing_section_override.id)
        expect(result[99_999]).to be_nil
      end
    end
  end

  describe "#services" do
    let(:service) do
      described_class.new(
        peer_review_sub_assignment:,
        overrides: []
      )
    end

    it "returns an empty hash by default" do
      expect(service.send(:services)).to eq({})
    end
  end

  describe "integration with ApplicationService" do
    let(:override_data) { [] }

    it "can be called via the class method" do
      result = described_class.call(
        peer_review_sub_assignment:,
        overrides: override_data
      )
      expect(result).to eq([])
    end
  end
end

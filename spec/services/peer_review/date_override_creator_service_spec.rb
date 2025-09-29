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

RSpec.describe PeerReview::DateOverrideCreatorService do
  describe "#initialize" do
    it "inherits from PeerReview::DateOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::DateOverrideCommonService)
    end

    it "sets peer_review_sub_assignment and overrides instance variables" do
      overrides = [{ id: 1, set_type: "CourseSection" }]
      service = described_class.new(
        peer_review_sub_assignment: nil,
        overrides:
      )

      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@overrides)).to eq(overrides)
    end

    it "can be initialized with nil values" do
      service = described_class.new
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@overrides)).to eq([])
    end
  end

  describe "#services" do
    let(:services) do
      service = described_class.new
      service.send(:services)
    end

    it "returns the expected services configuration" do
      expect(services).to eq({
                               "ADHOC" => PeerReview::AdhocOverrideCreatorService,
                               "CourseSection" => PeerReview::SectionOverrideCreatorService,
                               "Group" => PeerReview::GroupOverrideCreatorService,
                               "Course" => PeerReview::CourseOverrideCreatorService
                             })
    end

    it "includes supported set types" do
      expect(services.keys).to contain_exactly("ADHOC", "CourseSection", "Group", "Course")
      expect(services.values).to contain_exactly(PeerReview::AdhocOverrideCreatorService, PeerReview::SectionOverrideCreatorService, PeerReview::GroupOverrideCreatorService, PeerReview::CourseOverrideCreatorService)
    end
  end

  describe "#call" do
    let(:course) { course_model(name: "Test Course") }
    let(:peer_review_sub_assignment) { peer_review_model(course:) }
    let(:section) { add_section("Section 1", course:) }

    before do
      course.enable_feature!(:peer_review_allocation_and_grading)
    end

    context "with ADHOC overrides" do
      let(:students) { create_users_in_course(course, 2, return_type: :record) }
      let(:override_data) do
        [{
          set_type: "ADHOC",
          student_ids: students.map(&:id),
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: override_data
        )
      end

      it "calls AdhocOverrideCreatorService for ADHOC override" do
        expect(PeerReview::AdhocOverrideCreatorService).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[0]
        )

        service.call
      end
    end

    context "with CourseSection overrides" do
      let(:override_data) do
        [{
          set_type: "CourseSection",
          set_id: section.id,
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: override_data
        )
      end

      it "calls SectionOverrideCreatorService for CourseSection override" do
        expect(PeerReview::SectionOverrideCreatorService).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[0]
        )

        service.call
      end
    end

    context "with mixed override types" do
      let(:students) { create_users_in_course(course, 2, return_type: :record) }
      let(:override_data) do
        [
          {
            set_type: "ADHOC",
            student_ids: students.map(&:id),
            due_at: 1.week.from_now
          },
          {
            set_type: "CourseSection",
            set_id: section.id,
            due_at: 2.weeks.from_now
          }
        ]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: override_data
        )
      end

      it "calls the appropriate service for each override type" do
        expect(PeerReview::AdhocOverrideCreatorService).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[0]
        )
        expect(PeerReview::SectionOverrideCreatorService).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[1]
        )

        service.call
      end
    end

    context "with Group overrides" do
      let(:group_category) { course.group_categories.create!(name: "Project Groups") }
      let(:parent_assignment) do
        assignment_model(
          course:,
          title: "Group Assignment",
          group_category:
        )
      end
      let(:peer_review_sub_assignment_with_groups) { peer_review_model(parent_assignment:) }
      let(:group) { course.groups.create!(group_category:, name: "Group 1") }
      let(:override_data) do
        [{
          set_type: "Group",
          set_id: group.id,
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment: peer_review_sub_assignment_with_groups,
          overrides: override_data
        )
      end

      it "calls GroupOverrideCreatorService for Group override" do
        expect(PeerReview::GroupOverrideCreatorService).to receive(:call).with(
          peer_review_sub_assignment: peer_review_sub_assignment_with_groups,
          override: override_data[0]
        )

        service.call
      end
    end

    context "with unsupported set_type" do
      let(:unsupported_override) do
        [{
          set_type: "UnsupportedType",
          due_at: 2.weeks.from_now
        }]
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: unsupported_override
        )
      end

      it "raises error for unsupported set_type" do
        expect { service.call }.to raise_error(
          PeerReview::SetTypeNotSupportedError,
          "Set type 'UnsupportedType' is not supported. Supported types are: ADHOC, CourseSection, Group, Course"
        )
      end
    end

    context "with validation errors" do
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
    end

    context "with empty overrides" do
      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: []
        )
      end

      it "processes successfully with no overrides" do
        expect { service.call }.not_to raise_error
      end
    end
  end

  describe "integration with ApplicationService" do
    it "can be called via the class method" do
      result = described_class.call(
        peer_review_sub_assignment: nil,
        overrides: []
      )
      expect(result).to eq([])
    end
  end

  describe "inheritance behavior" do
    it "includes PeerReview::Validations module" do
      expect(described_class.included_modules).to include(PeerReview::Validations)
    end

    it "inherits validation methods from parent" do
      service = described_class.new
      expect(service).to respond_to(:validate_set_type_required)
      expect(service).to respond_to(:validate_set_type_supported)
    end
  end
end

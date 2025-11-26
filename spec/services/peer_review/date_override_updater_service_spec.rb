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

RSpec.describe PeerReview::DateOverrideUpdaterService do
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
                               "ADHOC" => PeerReview::AdhocOverrideUpdaterService,
                               "CourseSection" => PeerReview::SectionOverrideUpdaterService,
                               "Group" => PeerReview::GroupOverrideUpdaterService,
                               "Course" => PeerReview::CourseOverrideUpdaterService
                             })
    end

    it "includes supported set types" do
      expect(services.keys).to contain_exactly("ADHOC", "CourseSection", "Group", "Course")
      expect(services.values).to contain_exactly(PeerReview::AdhocOverrideUpdaterService, PeerReview::SectionOverrideUpdaterService, PeerReview::GroupOverrideUpdaterService, PeerReview::CourseOverrideUpdaterService)
    end
  end

  describe "#call" do
    let(:course) { course_model(name: "Test Course") }
    let(:peer_review_sub_assignment) { peer_review_model(course:) }
    let(:section) { add_section("Section 1", course:) }

    before do
      course.enable_feature!(:peer_review_allocation_and_grading)
    end

    context "with ADHOC override" do
      let(:students) { create_users_in_course(course, 2, return_type: :record) }
      let(:override_params) do
        {
          id: 456,
          set_type: "ADHOC",
          student_ids: students.map(&:id),
          due_at: 1.week.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: [override_params]
        )
      end

      it "delegates to AdhocOverrideUpdaterService" do
        expect(PeerReview::AdhocOverrideUpdaterService).to receive(:call)
          .with(
            peer_review_sub_assignment:,
            override: override_params
          )

        service.call
      end
    end

    context "with CourseSection override" do
      let(:override_params) do
        {
          id: 123,
          set_type: "CourseSection",
          set_id: section.id,
          due_at: 2.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: [override_params]
        )
      end

      it "delegates to SectionOverrideUpdaterService" do
        expect(PeerReview::SectionOverrideUpdaterService).to receive(:call)
          .with(
            peer_review_sub_assignment:,
            override: override_params
          )

        service.call
      end
    end

    context "with mixed override types" do
      let(:students) { create_users_in_course(course, 2, return_type: :record) }
      let(:override_data) do
        [
          {
            id: 456,
            set_type: "ADHOC",
            student_ids: students.map(&:id),
            due_at: 1.week.from_now
          },
          {
            id: 123,
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

      it "delegates to the appropriate updater service for each override type" do
        expect(PeerReview::AdhocOverrideUpdaterService).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[0]
        )
        expect(PeerReview::SectionOverrideUpdaterService).to receive(:call).with(
          peer_review_sub_assignment:,
          override: override_data[1]
        )

        service.call
      end
    end

    context "with Group override" do
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
      let(:override_params) do
        {
          id: 789,
          set_type: "Group",
          set_id: group.id,
          due_at: 2.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment: peer_review_sub_assignment_with_groups,
          overrides: [override_params]
        )
      end

      it "delegates to GroupOverrideUpdaterService" do
        expect(PeerReview::GroupOverrideUpdaterService).to receive(:call)
          .with(
            peer_review_sub_assignment: peer_review_sub_assignment_with_groups,
            override: override_params
          )

        service.call
      end
    end

    context "with unsupported set_type" do
      let(:override_params) do
        {
          id: 123,
          set_type: "UnsupportedType",
          due_at: 2.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: [override_params]
        )
      end

      it "raises SetTypeNotSupportedError" do
        expect { service.call }.to raise_error(
          PeerReview::SetTypeNotSupportedError,
          "Set type 'UnsupportedType' is not supported. Supported types are: ADHOC, CourseSection, Group, Course"
        )
      end
    end

    context "with missing set_type" do
      let(:override_params) do
        {
          id: nil,
          due_at: 2.weeks.from_now
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          overrides: [override_params]
        )
      end

      it "raises SetTypeRequiredError" do
        expect { service.call }.to raise_error(
          PeerReview::SetTypeRequiredError,
          "Set type is required"
        )
      end
    end
  end

  describe "inheritance" do
    it "inherits from DateOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::DateOverrideCommonService)
    end

    it "includes PeerReview::Validations through parent class" do
      service = described_class.new(
        peer_review_sub_assignment: nil,
        overrides: []
      )

      expect(service).to respond_to(:validate_set_type_required)
      expect(service).to respond_to(:validate_set_type_supported)
    end
  end

  describe "integration with ApplicationService" do
    let(:course) { course_model(name: "Test Course") }
    let(:peer_review_sub_assignment) { peer_review_model(course:) }
    let(:section) { add_section("Section 1", course:) }

    before do
      course.enable_feature!(:peer_review_allocation_and_grading)
    end

    it "responds to the call class method" do
      expect(described_class).to respond_to(:call)
    end

    it "can be called as a class method" do
      override_params = {
        id: 123,
        set_type: "CourseSection",
        set_id: section.id,
        due_at: 2.weeks.from_now
      }

      expect(PeerReview::SectionOverrideUpdaterService).to receive(:call)

      described_class.call(
        peer_review_sub_assignment:,
        overrides: [override_params]
      )
    end
  end
end

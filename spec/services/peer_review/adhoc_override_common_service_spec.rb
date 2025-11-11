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

RSpec.describe PeerReview::AdhocOverrideCommonService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:students) { create_users_in_course(course, 3, return_type: :record) }
  let(:override_params) do
    {
      set_type: "ADHOC",
      student_ids: students.map(&:id),
      due_at: 2.days.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 3.days.from_now,
      unassign_item: false
    }
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      service = described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )

      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_params)
    end

    it "allows nil values for both parameters" do
      service = described_class.new
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@override)).to eq({})
    end
  end

  describe "#fetch_student_ids" do
    let(:service) { described_class.new(override: override_params) }

    it "returns the student_ids value from the override" do
      expect(service.send(:fetch_student_ids)).to eq(students.map(&:id))
    end

    context "when override contains student_ids as nil" do
      let(:override_with_nil) { override_params.merge(student_ids: nil) }
      let(:service_with_nil) { described_class.new(override: override_with_nil) }

      it "returns nil" do
        expect(service_with_nil.send(:fetch_student_ids)).to be_nil
      end
    end

    context "when override does not contain student_ids" do
      let(:override_without_student_ids) { override_params.except(:student_ids) }
      let(:service_without_student_ids) { described_class.new(override: override_without_student_ids) }

      it "returns nil" do
        expect(service_without_student_ids.send(:fetch_student_ids)).to be_nil
      end
    end

    context "when override is nil" do
      let(:service_without_override) { described_class.new }

      it "returns nil when key is not found" do
        expect(service_without_override.send(:fetch_student_ids)).to be_nil
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

  describe "#override_title" do
    let(:service) { described_class.new }

    it "delegates to AssignmentOverride.title_from_student_count" do
      expect(AssignmentOverride).to receive(:title_from_student_count).with(3).and_return("3 students")
      result = service.send(:override_title, students.map(&:id))
      expect(result).to eq("3 students")
    end

    it "works with different student counts" do
      single_student = [students.first.id]
      expect(AssignmentOverride).to receive(:title_from_student_count).with(1).and_return("1 student")
      result = service.send(:override_title, single_student)
      expect(result).to eq("1 student")
    end
  end

  describe "#build_override_students" do
    let(:service) { described_class.new }
    let!(:parent_override) do
      assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set_type: "ADHOC")
    end
    let(:override) do
      assignment_override_model(assignment: peer_review_sub_assignment, set_type: "ADHOC", parent_override_id: parent_override.id)
    end

    context "when no existing student overrides" do
      it "builds student overrides for all provided student IDs" do
        expect(override.assignment_override_students.size).to eq(0)
        service.send(:build_override_students, override, students.map(&:id))

        expect(override.assignment_override_students.size).to eq(3)
        expect(override.assignment_override_students.map(&:user_id)).to match_array(students.map(&:id))
        expect(override.changed_student_ids).to match_array(students.to_set(&:id))
      end
    end

    context "when some student overrides already exist" do
      before do
        override.assignment_override_students.create!(user_id: students[0].id)
      end

      it "only builds student overrides for new student IDs" do
        all_student_ids = students.map(&:id)
        initial_count = override.assignment_override_students.size

        service.send(:build_override_students, override, all_student_ids)

        expect(override.assignment_override_students.size).to eq(initial_count + 2)
        expect(override.changed_student_ids).to match_array([students[1].id, students[2].id].to_set)
      end
    end

    context "when all student overrides already exist" do
      before do
        students.each do |student|
          override.assignment_override_students.create!(user_id: student.id)
        end
      end

      it "does not build any new student overrides" do
        expect { service.send(:build_override_students, override, students.map(&:id)) }
          .not_to change { override.assignment_override_students.size }
        expect(override.changed_student_ids).to be_a(Set)
        expect(override.changed_student_ids).to be_empty
      end
    end

    it "initializes changed_student_ids as empty set" do
      service.send(:build_override_students, override, [])
      expect(override.changed_student_ids).to be_a(Set)
      expect(override.changed_student_ids).to be_empty
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
      expect(service).to respond_to(:validate_student_ids_required)
      expect(service).to respond_to(:validate_student_ids_in_course)
      expect(service).to respond_to(:validate_override_exists)
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

  describe "#find_student_ids_in_course" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }
    let(:course_students) { students }

    it "returns student IDs that exist in the course" do
      student_ids = students.map(&:id)
      result = service.send(:find_student_ids_in_course, student_ids)
      expect(result).to match_array(student_ids)
    end

    context "when some student IDs do not exist in the course" do
      it "returns only the student IDs that exist in the course" do
        valid_student_ids = [students[0].id, students[1].id]
        invalid_student_ids = [999, 1000]
        all_student_ids = valid_student_ids + invalid_student_ids

        result = service.send(:find_student_ids_in_course, all_student_ids)
        expect(result).to match_array(valid_student_ids)
      end
    end

    context "when no student IDs exist in the course" do
      it "returns an empty array" do
        invalid_student_ids = [999, 1000, 1001]
        result = service.send(:find_student_ids_in_course, invalid_student_ids)
        expect(result).to be_empty
      end
    end

    context "when student IDs array is empty" do
      it "returns an empty array" do
        result = service.send(:find_student_ids_in_course, [])
        expect(result).to be_empty
      end
    end

    context "when student IDs contain duplicates" do
      it "returns unique student IDs" do
        duplicate_student_ids = [students[0].id, students[0].id, students[1].id, students[1].id]
        expected_unique_ids = [students[0].id, students[1].id]

        result = service.send(:find_student_ids_in_course, duplicate_student_ids)
        expect(result).to match_array(expected_unique_ids)
      end
    end

    context "when course has inactive enrollments" do
      before do
        students[0].enrollments.first.update!(workflow_state: "inactive")
      end

      it "returns all student ids including ones with inactive enrollments" do
        student_ids = students.map(&:id)

        result = service.send(:find_student_ids_in_course, student_ids)
        expect(result).to match_array(student_ids)
      end
    end

    context "when course has different enrollment types" do
      let(:teacher) { teacher_in_course(course:, active_all: true).user }
      let(:ta) { ta_in_course(course:, active_all: true).user }

      it "only returns student ids, not teacher or TA ids" do
        all_user_ids = students.map(&:id) + [teacher.id, ta.id]
        expected_student_ids = students.map(&:id)

        result = service.send(:find_student_ids_in_course, all_user_ids)
        expect(result).to match_array(expected_student_ids)
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
        expect(service_with_extras.send(:fetch_student_ids)).to eq(students.map(&:id))
        expect(service_with_extras.send(:fetch_unassign_item)).to be false
      end
    end

    context "with empty student IDs array" do
      let(:service) { described_class.new }
      let!(:parent_override) do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set_type: "ADHOC")
      end
      let(:override) do
        assignment_override_model(assignment: peer_review_sub_assignment, set_type: "ADHOC", parent_override_id: parent_override.id)
      end

      it "handles empty student IDs gracefully" do
        service.send(:build_override_students, override, [])
        expect(override.assignment_override_students.size).to eq(0)
        expect(override.changed_student_ids).to be_a(Set)
        expect(override.changed_student_ids).to be_empty
      end
    end
  end

  describe "#find_parent_override" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    context "when parent override exists with matching student IDs" do
      let!(:parent_override) do
        override = parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        students.each do |student|
          override.assignment_override_students.build(user: student)
        end
        override.save!
        override
      end

      it "finds the parent override based on student IDs" do
        result = service.send(:find_parent_override, students.map(&:id))
        expect(result).to eq(parent_override)
      end

      it "finds parent override regardless of student ID order" do
        shuffled_ids = students.map(&:id).shuffle
        result = service.send(:find_parent_override, shuffled_ids)
        expect(result).to eq(parent_override)
      end

      it "normalizes student IDs by converting to integers" do
        string_ids = students.map { |s| s.id.to_s }
        result = service.send(:find_parent_override, string_ids)
        expect(result).to eq(parent_override)
      end
    end

    context "when parent override does not exist" do
      it "returns nil" do
        result = service.send(:find_parent_override, students.map(&:id))
        expect(result).to be_nil
      end
    end

    context "when parent override exists but with different student IDs" do
      let(:other_students) { create_users_in_course(course, 2, return_type: :record) }
      let(:parent_override) do
        override = parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        other_students.each do |student|
          override.assignment_override_students.build(user: student)
        end
        override.save!
        override
      end

      it "returns nil" do
        result = service.send(:find_parent_override, students.map(&:id))
        expect(result).to be_nil
      end
    end

    context "when parent override exists but with subset of student IDs" do
      let(:parent_override) do
        override = parent_assignment.assignment_overrides.build(set_type: AssignmentOverride::SET_TYPE_ADHOC)
        [students[0], students[1]].each do |student|
          override.assignment_override_students.build(user: student)
        end
        override.save!
        override
      end

      it "returns nil because student lists don't match exactly" do
        result = service.send(:find_parent_override, students.map(&:id))
        expect(result).to be_nil
      end
    end
  end

  describe "#parent_assignment" do
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

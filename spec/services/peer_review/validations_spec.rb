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

RSpec.describe PeerReview::Validations do
  let(:course) { course_model(name: "Course with Assignment") }
  let(:parent_assignment) do
    assignment_model(
      course:,
      title: "Parent Assignment",
      points_possible: 10,
      grading_type: "points",
      due_at: 1.week.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 2.weeks.from_now,
      peer_review_count: 2,
      peer_reviews: true,
      submission_types: "online_text_entry"
    )
  end

  let(:test_service_class) do
    Class.new do
      include PeerReview::Validations

      def initialize(parent_assignment:, peer_review_overrides: [])
        @parent_assignment = parent_assignment
        @peer_review_overrides = peer_review_overrides
      end
    end
  end

  let(:service) { test_service_class.new(parent_assignment:) }

  before do
    course.enable_feature!(:peer_review_allocation_and_grading)
  end

  describe "#validate_parent_assignment" do
    it "does not raise an error for a valid parent assignment" do
      expect { service.validate_parent_assignment(parent_assignment) }.not_to raise_error
    end

    it "raises an error when parent assignment is nil" do
      assignment = nil
      expect { service.validate_parent_assignment(assignment) }.to raise_error(
        PeerReview::InvalidParentAssignmentError,
        "Invalid parent assignment"
      )
    end

    it "raises an error when parent assignment is not an Assignment object" do
      assignment = "not_an_assignment"
      expect { service.validate_parent_assignment(assignment) }.to raise_error(
        PeerReview::InvalidParentAssignmentError,
        "Invalid parent assignment"
      )
    end

    it "raises an error when parent assignment is an Assignment but not persisted" do
      new_assignment = Assignment.new(context: course, title: "New Assignment")
      expect { service.validate_parent_assignment(new_assignment) }.to raise_error(
        PeerReview::InvalidParentAssignmentError,
        "Invalid parent assignment"
      )
    end

    it "raises an error when parent assignment is a Hash" do
      assignment = { id: 1 }
      expect { service.validate_parent_assignment(assignment) }.to raise_error(
        PeerReview::InvalidParentAssignmentError,
        "Invalid parent assignment"
      )
    end

    it "raises an error when parent assignment is a blank string" do
      assignment = ""
      expect { service.validate_parent_assignment(assignment) }.to raise_error(
        PeerReview::InvalidParentAssignmentError,
        "Invalid parent assignment"
      )
    end
  end

  describe "#validate_peer_reviews_enabled" do
    it "does not raise an error when peer reviews are enabled" do
      expect { service.validate_peer_reviews_enabled(parent_assignment) }.not_to raise_error
    end

    it "raises an error when peer reviews are disabled" do
      parent_assignment.update!(peer_reviews: false)
      expect { service.validate_peer_reviews_enabled(parent_assignment) }.to raise_error(
        PeerReview::PeerReviewsNotEnabledError,
        "Peer reviews are not enabled for this assignment"
      )
    end

    it "raises an error when peer reviews are nil" do
      parent_assignment.update!(peer_reviews: nil)
      expect { service.validate_peer_reviews_enabled(parent_assignment) }.to raise_error(
        PeerReview::PeerReviewsNotEnabledError,
        "Peer reviews are not enabled for this assignment"
      )
    end
  end

  describe "#validate_feature_enabled" do
    it "does not raise an error when feature is enabled" do
      expect { service.validate_feature_enabled(parent_assignment) }.not_to raise_error
    end

    it "raises an error when feature is disabled" do
      course.disable_feature!(:peer_review_allocation_and_grading)
      expect { service.validate_feature_enabled(parent_assignment) }.to raise_error(
        PeerReview::FeatureDisabledError,
        "Peer Review Allocation and Grading feature flag is disabled"
      )
    end

    it "raises an error when feature is not available for the context" do
      allow(parent_assignment.context).to receive(:feature_enabled?).with(:peer_review_allocation_and_grading).and_return(false)
      expect { service.validate_feature_enabled(parent_assignment) }.to raise_error(
        PeerReview::FeatureDisabledError,
        "Peer Review Allocation and Grading feature flag is disabled"
      )
    end
  end

  describe "#validate_assignment_submission_types" do
    it "does not raise an error for non-external tool assignments" do
      expect { service.validate_assignment_submission_types(parent_assignment) }.not_to raise_error
    end

    it "raises an error for external tool assignments" do
      external_tool_assignment = assignment_model(
        course:,
        title: "External Tool Assignment",
        submission_types: "external_tool"
      )

      expect { service.validate_assignment_submission_types(external_tool_assignment) }.to raise_error(
        PeerReview::InvalidAssignmentSubmissionTypesError,
        "Peer reviews cannot be used with External Tool assignments"
      )
    end

    it "does not raise an error for assignments with multiple submission types including online_text_entry" do
      parent_assignment.update!(submission_types: "online_text_entry,online_upload,media_recording")
      expect { service.validate_assignment_submission_types(parent_assignment) }.not_to raise_error
    end

    it "does not raise an error for assignments with only online_upload" do
      parent_assignment.update!(submission_types: "online_upload")
      expect { service.validate_assignment_submission_types(parent_assignment) }.not_to raise_error
    end

    it "raises an error for assignments with discussion_topic submission type" do
      parent_assignment.update!(submission_types: "discussion_topic")
      expect { service.validate_assignment_submission_types(parent_assignment) }.to raise_error(
        PeerReview::InvalidAssignmentSubmissionTypesError,
        "Peer reviews cannot be used with Discussion Topic assignments"
      )
    end
  end

  describe "#validate_peer_review_sub_assignment_exists" do
    it "does not raise an error when peer review sub assignment exists" do
      PeerReviewSubAssignment.create!(parent_assignment:)
      expect { service.validate_peer_review_sub_assignment_exists(parent_assignment) }.not_to raise_error
    end

    it "raises an error when peer review sub assignment does not exist" do
      expect { service.validate_peer_review_sub_assignment_exists(parent_assignment) }.to raise_error(
        PeerReview::SubAssignmentNotExistError,
        "Peer review sub assignment does not exist"
      )
    end

    it "raises an error when peer review sub assignment is nil" do
      allow(parent_assignment).to receive(:peer_review_sub_assignment).and_return(nil)
      expect { service.validate_peer_review_sub_assignment_exists(parent_assignment) }.to raise_error(
        PeerReview::SubAssignmentNotExistError,
        "Peer review sub assignment does not exist"
      )
    end
  end

  describe "#validate_peer_review_sub_assignment_not_exist" do
    it "does not raise an error when no peer review sub assignment exists" do
      expect { service.validate_peer_review_sub_assignment_not_exist(parent_assignment) }.not_to raise_error
    end

    it "raises an error when peer review sub assignment already exists" do
      PeerReviewSubAssignment.create!(parent_assignment:)
      expect { service.validate_peer_review_sub_assignment_not_exist(parent_assignment) }.to raise_error(
        PeerReview::SubAssignmentExistsError,
        "Peer review sub assignment exists"
      )
    end

    it "handles case where peer review sub assignment is present but empty" do
      allow(parent_assignment).to receive(:peer_review_sub_assignment).and_return("")
      expect { service.validate_peer_review_sub_assignment_not_exist(parent_assignment) }.not_to raise_error
    end

    it "handles case where peer review sub assignment association returns nil" do
      allow(parent_assignment).to receive(:peer_review_sub_assignment).and_return(nil)
      expect { service.validate_peer_review_sub_assignment_not_exist(parent_assignment) }.not_to raise_error
    end
  end

  describe "#validate_peer_review_dates" do
    context "with valid date combinations" do
      it "does not raise an error when all dates are in correct order" do
        peer_review_dates = {
          due_at: 3.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 1.week.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when only due_at is provided" do
        peer_review_dates = { due_at: 3.days.from_now }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when only unlock_at is provided" do
        peer_review_dates = { unlock_at: 1.day.from_now }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when only lock_at is provided" do
        peer_review_dates = { lock_at: 1.week.from_now }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when due_at equals unlock_at" do
        same_time = 2.days.from_now
        peer_review_dates = {
          due_at: same_time,
          unlock_at: same_time
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when due_at equals lock_at" do
        same_time = 2.days.from_now
        peer_review_dates = {
          due_at: same_time,
          lock_at: same_time
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when unlock_at equals lock_at" do
        same_time = 2.days.from_now
        peer_review_dates = {
          unlock_at: same_time,
          lock_at: same_time
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end
    end

    context "with invalid date combinations" do
      it "raises an error when due date is before unlock date" do
        peer_review_dates = {
          due_at: 1.day.from_now,
          unlock_at: 2.days.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Due date cannot be before unlock date"
        )
      end

      it "raises an error when due date is after lock date" do
        peer_review_dates = {
          due_at: 1.week.from_now,
          lock_at: 3.days.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Due date cannot be after lock date"
        )
      end

      it "raises an error when unlock date is after lock date" do
        peer_review_dates = {
          unlock_at: 1.week.from_now,
          lock_at: 3.days.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Unlock date cannot be after lock date"
        )
      end

      it "raises error for multiple invalid conditions with due_at before unlock_at taking precedence" do
        peer_review_dates = {
          due_at: 1.day.from_now,
          unlock_at: 2.days.from_now,
          lock_at: 3.hours.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Due date cannot be before unlock date"
        )
      end
    end

    context "with nil date values" do
      it "does not raise an error when all dates are nil" do
        peer_review_dates = {
          due_at: nil,
          unlock_at: nil,
          lock_at: nil
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise an error when some dates are nil" do
        peer_review_dates = {
          due_at: 2.days.from_now,
          unlock_at: nil,
          lock_at: 1.week.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "handles empty hash" do
        peer_review_dates = {}
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end
    end

    context "with string date values" do
      it "handles string dates correctly" do
        base_time = Time.zone.now
        peer_review_dates = {
          due_at: (base_time + 3.days).iso8601,
          unlock_at: (base_time + 1.day).iso8601,
          lock_at: (base_time + 1.week).iso8601
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "raises error when string dates are in wrong order" do
        base_time = Time.zone.now
        peer_review_dates = {
          due_at: (base_time + 1.day).iso8601,
          unlock_at: (base_time + 2.days).iso8601
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Due date cannot be before unlock date"
        )
      end

      it "handles mixed Time objects and string dates correctly" do
        base_time = Time.zone.now
        peer_review_dates = {
          due_at: base_time + 3.days,
          unlock_at: (base_time + 1.day).iso8601,
          lock_at: base_time + 1.week
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "validates string format even when mixed with Time objects" do
        peer_review_dates = {
          due_at: 3.days.from_now,
          unlock_at: "invalid_date"
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Invalid datetime format for unlock_at"
        )
      end
    end

    context "with invalid date format validation" do
      it "does not raise an error for valid ISO8601 date strings" do
        peer_review_dates = {
          due_at: "2025-10-10T12:00:00-06:00",
          unlock_at: "2025-10-01T10:00:00-06:00",
          lock_at: "2025-10-15T23:59:59-06:00"
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "raises an error for invalid due_at date format" do
        peer_review_dates = { due_at: "2025-10-01" }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Invalid datetime format for due_at"
        )
      end

      it "raises an error for invalid unlock_at date format" do
        peer_review_dates = { unlock_at: "10/01/2025" }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Invalid datetime format for unlock_at"
        )
      end

      it "raises an error for invalid lock_at date format" do
        peer_review_dates = { lock_at: "bad_date" }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Invalid datetime format for lock_at"
        )
      end

      it "raises format error before date relationship validation" do
        peer_review_dates = {
          due_at: "invalid_date",
          unlock_at: "2025-10-15T12:00:00-06:00"
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Invalid datetime format for due_at"
        )
      end

      it "does not raise format error for nil date values" do
        peer_review_dates = {
          due_at: nil,
          unlock_at: nil,
          lock_at: nil
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise format error for Time objects" do
        peer_review_dates = {
          due_at: 3.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 1.week.from_now
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "does not raise format error for empty string values" do
        peer_review_dates = {
          due_at: "",
          unlock_at: "",
          lock_at: ""
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.not_to raise_error
      end

      it "raises error for multiple invalid date formats, checking due_at first" do
        peer_review_dates = {
          due_at: "invalid_date",
          unlock_at: "also_invalid",
          lock_at: "bad_format"
        }
        expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          "Invalid datetime format for due_at"
        )
      end
    end
  end

  describe "error message internationalization" do
    it "calls I18n.t for parent assignment validation error" do
      expect(I18n).to receive(:t).with("Invalid parent assignment").and_call_original

      expect { service.validate_parent_assignment(nil) }.to raise_error(
        PeerReview::InvalidParentAssignmentError
      )
    end

    it "calls I18n.t for peer reviews disabled error" do
      parent_assignment.update!(peer_reviews: false)
      expect(I18n).to receive(:t).with("Peer reviews are not enabled for this assignment").and_call_original

      expect { service.validate_peer_reviews_enabled(parent_assignment) }.to raise_error(
        PeerReview::PeerReviewsNotEnabledError
      )
    end

    it "calls I18n.t for feature disabled error" do
      course.disable_feature!(:peer_review_allocation_and_grading)
      expect(I18n).to receive(:t).with("Peer Review Allocation and Grading feature flag is disabled").and_call_original

      expect { service.validate_feature_enabled(parent_assignment) }.to raise_error(
        PeerReview::FeatureDisabledError
      )
    end

    it "calls I18n.t for external tool assignment error" do
      parent_assignment.update!(submission_types: "external_tool")
      expect(I18n).to receive(:t).with("Peer reviews cannot be used with External Tool assignments").and_call_original

      expect { service.validate_assignment_submission_types(parent_assignment) }.to raise_error(
        PeerReview::InvalidAssignmentSubmissionTypesError
      )
    end

    it "calls I18n.t for peer review sub assignment exists error" do
      PeerReviewSubAssignment.create!(parent_assignment:)
      expect(I18n).to receive(:t).with("Peer review sub assignment exists").and_call_original

      expect { service.validate_peer_review_sub_assignment_not_exist(parent_assignment) }.to raise_error(
        PeerReview::SubAssignmentExistsError
      )
    end

    it "calls I18n.t for peer review sub assignment not exist error" do
      expect { service.validate_peer_review_sub_assignment_exists(parent_assignment) }.to raise_error(
        PeerReview::SubAssignmentNotExistError,
        "Peer review sub assignment does not exist"
      )
    end

    it "calls I18n.t for invalid peer review dates errors" do
      peer_review_dates = {
        due_at: 1.day.from_now,
        unlock_at: 2.days.from_now
      }
      expect(I18n).to receive(:t).with("Due date cannot be before unlock date").and_call_original

      expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
        PeerReview::InvalidDatesError
      )
    end

    it "calls I18n.t for invalid date format errors" do
      peer_review_dates = { due_at: "invalid_date" }
      expect(I18n).to receive(:t).with("Invalid datetime format for %{attribute}", { attribute: "due_at" }).and_call_original

      expect { service.validate_peer_review_dates(peer_review_dates) }.to raise_error(
        PeerReview::InvalidDatesError
      )
    end
  end

  describe "#validate_set_type_required" do
    it "does not raise an error when set_type is present" do
      expect { service.validate_set_type_required("CourseSection") }.not_to raise_error
    end

    it "raises an error when set_type is nil" do
      expect { service.validate_set_type_required(nil) }.to raise_error(
        PeerReview::SetTypeRequiredError,
        "Set type is required"
      )
    end

    it "raises an error when set_type is empty string" do
      expect { service.validate_set_type_required("") }.to raise_error(
        PeerReview::SetTypeRequiredError,
        "Set type is required"
      )
    end

    it "raises an error when set_type is blank" do
      expect { service.validate_set_type_required("   ") }.to raise_error(
        PeerReview::SetTypeRequiredError,
        "Set type is required"
      )
    end
  end

  describe "#validate_set_id_required" do
    it "does not raise an error when set_id is present" do
      expect { service.validate_set_id_required(123) }.not_to raise_error
    end

    it "does not raise an error when set_id is a string" do
      expect { service.validate_set_id_required("123") }.not_to raise_error
    end

    it "raises an error when set_id is nil" do
      expect { service.validate_set_id_required(nil) }.to raise_error(
        PeerReview::SetIdRequiredError,
        "Set id is required"
      )
    end

    it "raises an error when set_id is empty string" do
      expect { service.validate_set_id_required("") }.to raise_error(
        PeerReview::SetIdRequiredError,
        "Set id is required"
      )
    end

    it "raises an error when set_id is blank" do
      expect { service.validate_set_id_required("   ") }.to raise_error(
        PeerReview::SetIdRequiredError,
        "Set id is required"
      )
    end
  end

  describe "#validate_set_type_supported" do
    let(:services) do
      {
        "CourseSection" => "SectionService",
        "Group" => "GroupService"
      }
    end

    it "does not raise an error when set_type is supported" do
      expect { service.validate_set_type_supported("CourseSection", services) }.not_to raise_error
    end

    it "does not raise an error when set_type is another supported type" do
      expect { service.validate_set_type_supported("Group", services) }.not_to raise_error
    end

    it "raises an error when set_type is not supported" do
      expect { service.validate_set_type_supported("UnsupportedType", services) }.to raise_error(
        PeerReview::SetTypeNotSupportedError,
        "Set type 'UnsupportedType' is not supported. Supported types are: CourseSection, Group"
      )
    end

    it "raises an error with single supported type when only one type is available" do
      single_service = { "CourseSection" => "SectionService" }
      expect { service.validate_set_type_supported("UnsupportedType", single_service) }.to raise_error(
        PeerReview::SetTypeNotSupportedError,
        "Set type 'UnsupportedType' is not supported. Supported types are: CourseSection"
      )
    end

    it "raises an error when services hash is empty" do
      expect { service.validate_set_type_supported("CourseSection", {}) }.to raise_error(
        PeerReview::SetTypeNotSupportedError,
        "Set type 'CourseSection' is not supported. Supported types are: "
      )
    end

    it "uses I18n.t for error message" do
      expect(I18n).to receive(:t).with(
        "Set type '%{set_type}' is not supported. Supported types are: %{supported_types}",
        { set_type: "UnsupportedType", supported_types: "CourseSection, Group" }
      ).and_call_original

      expect { service.validate_set_type_supported("UnsupportedType", services) }.to raise_error(
        PeerReview::SetTypeNotSupportedError
      )
    end
  end

  describe "#validate_override_exists" do
    let(:mock_override) { double("override") }

    it "does not raise an error when override is present" do
      expect { service.validate_override_exists(mock_override) }.not_to raise_error
    end

    it "raises an error when override is nil" do
      expect { service.validate_override_exists(nil) }.to raise_error(
        PeerReview::OverrideNotFoundError,
        "Override does not exist"
      )
    end

    it "raises an error when override is false" do
      expect { service.validate_override_exists(false) }.to raise_error(
        PeerReview::OverrideNotFoundError,
        "Override does not exist"
      )
    end

    it "raises an error when override is empty string" do
      expect { service.validate_override_exists("") }.to raise_error(
        PeerReview::OverrideNotFoundError,
        "Override does not exist"
      )
    end
  end

  describe "#validate_section_exists" do
    let(:mock_section) { double("section") }

    it "does not raise an error when section is present" do
      expect { service.validate_section_exists(mock_section) }.not_to raise_error
    end

    it "raises an error when section is nil" do
      expect { service.validate_section_exists(nil) }.to raise_error(
        PeerReview::SectionNotFoundError,
        "Section does not exist"
      )
    end

    it "raises an error when section is false" do
      expect { service.validate_section_exists(false) }.to raise_error(
        PeerReview::SectionNotFoundError,
        "Section does not exist"
      )
    end

    it "raises an error when section is empty string" do
      expect { service.validate_section_exists("") }.to raise_error(
        PeerReview::SectionNotFoundError,
        "Section does not exist"
      )
    end
  end

  describe "#validate_student_ids_required" do
    it "does not raise an error when student_ids is a non-empty array" do
      expect { service.validate_student_ids_required([1, 2, 3]) }.not_to raise_error
    end

    it "does not raise an error when student_ids is a single element array" do
      expect { service.validate_student_ids_required([1]) }.not_to raise_error
    end

    it "raises an error when student_ids is nil" do
      expect { service.validate_student_ids_required(nil) }.to raise_error(
        PeerReview::StudentIdsRequiredError,
        "Student ids are required"
      )
    end

    it "raises an error when student_ids is empty array" do
      expect { service.validate_student_ids_required([]) }.to raise_error(
        PeerReview::StudentIdsRequiredError,
        "Student ids are required"
      )
    end

    it "raises an error when student_ids is empty string" do
      expect { service.validate_student_ids_required("") }.to raise_error(
        PeerReview::StudentIdsRequiredError,
        "Student ids are required"
      )
    end

    it "raises an error when student_ids is blank string" do
      expect { service.validate_student_ids_required("   ") }.to raise_error(
        PeerReview::StudentIdsRequiredError,
        "Student ids are required"
      )
    end
  end

  describe "#validate_group_assignment_required" do
    context "when parent assignment has group_category_id" do
      let(:group_category) { course.group_categories.create!(name: "Project Groups") }
      let(:group_assignment) do
        assignment_model(
          course:,
          title: "Group Assignment",
          group_category:
        )
      end
      let(:peer_review_sub_assignment_for_group_assignment) do
        peer_review_model(parent_assignment: group_assignment)
      end

      it "does not raise an error" do
        expect { service.validate_group_assignment_required(peer_review_sub_assignment_for_group_assignment) }.not_to raise_error
      end

      it "does not raise an error when group_category_id is set" do
        peer_review_sub_assignment_for_group_assignment.group_category_id = group_category.id
        expect { service.validate_group_assignment_required(peer_review_sub_assignment_for_group_assignment) }.not_to raise_error
      end
    end

    context "when parent assignment does not have group_category_id" do
      let(:non_group_assignment) { assignment_model(course:, title: "Non-group Assignment") }
      let(:peer_review_sub_assignment_for_non_group_assignment) do
        peer_review_model(parent_assignment: non_group_assignment)
      end

      it "raises GroupAssignmentRequiredError" do
        expect { service.validate_group_assignment_required(peer_review_sub_assignment_for_non_group_assignment) }.to raise_error(
          PeerReview::GroupAssignmentRequiredError,
          "Must be a group assignment to create group overrides"
        )
      end

      it "raises GroupAssignmentRequiredError when group_category_id is explicitly nil" do
        peer_review_sub_assignment_for_non_group_assignment.group_category_id = nil
        expect { service.validate_group_assignment_required(peer_review_sub_assignment_for_non_group_assignment) }.to raise_error(
          PeerReview::GroupAssignmentRequiredError,
          "Must be a group assignment to create group overrides"
        )
      end
    end

    it "uses I18n.t for error message" do
      non_group_assignment = assignment_model(course:, title: "Non-group Assignment")
      peer_review_sub_assignment_for_non_group_assignment = peer_review_model(parent_assignment: non_group_assignment)
      expect(I18n).to receive(:t).with("Must be a group assignment to create group overrides").and_call_original

      expect { service.validate_group_assignment_required(peer_review_sub_assignment_for_non_group_assignment) }.to raise_error(
        PeerReview::GroupAssignmentRequiredError
      )
    end
  end

  describe "#validate_group_exists" do
    let(:group_category) { course.group_categories.create!(name: "Project Groups") }
    let(:group) { group_category.groups.create!(context: course, name: "Group 1") }

    it "does not raise an error when group is present" do
      expect { service.validate_group_exists(group) }.not_to raise_error
    end

    it "raises an error when group is nil" do
      expect { service.validate_group_exists(nil) }.to raise_error(
        PeerReview::GroupNotFoundError,
        "Group does not exist"
      )
    end

    it "uses I18n.t for error message" do
      expect(I18n).to receive(:t).with("Group does not exist").and_call_original

      expect { service.validate_group_exists(nil) }.to raise_error(
        PeerReview::GroupNotFoundError
      )
    end
  end

  describe "#validate_adhoc_parent_override_exists" do
    let(:students) { create_users_in_course(course, 3, return_type: :record) }
    let(:student_ids) { students.map(&:id) }
    let(:mock_parent_override) { double("parent_override") }

    it "does not raise an error when parent override is present" do
      expect { service.validate_adhoc_parent_override_exists(mock_parent_override, student_ids) }.not_to raise_error
    end

    it "raises ParentOverrideNotFoundError when parent override is nil" do
      expect { service.validate_adhoc_parent_override_exists(nil, student_ids) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /Parent assignment ADHOC override not found for students/
      )
    end

    it "includes student IDs in error message" do
      expect { service.validate_adhoc_parent_override_exists(nil, student_ids) }.to raise_error do |error|
        expect(error).to be_a(PeerReview::ParentOverrideNotFoundError)
        student_ids.each do |id|
          expect(error.message).to include(id.to_s)
        end
      end
    end

    it "formats student IDs as comma-separated list in error message" do
      expect { service.validate_adhoc_parent_override_exists(nil, [1, 2, 3]) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /1, 2, 3/
      )
    end

    it "uses I18n.t for error message" do
      expect(I18n).to receive(:t).with(
        "Parent assignment ADHOC override not found for students %{student_ids}",
        { student_ids: student_ids.join(", ") }
      ).and_call_original

      expect { service.validate_adhoc_parent_override_exists(nil, student_ids) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "does not raise an error when parent override is false" do
      expect { service.validate_adhoc_parent_override_exists(false, student_ids) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end
  end

  describe "#validate_course_parent_override_exists" do
    let(:course_id) { course.id }
    let(:mock_parent_override) { double("parent_override") }

    it "does not raise an error when parent override is present" do
      expect { service.validate_course_parent_override_exists(mock_parent_override, course_id) }.not_to raise_error
    end

    it "raises ParentOverrideNotFoundError when parent override is nil" do
      expect { service.validate_course_parent_override_exists(nil, course_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /Parent assignment Course override not found for course/
      )
    end

    it "includes course ID in error message" do
      expect { service.validate_course_parent_override_exists(nil, course_id) }.to raise_error do |error|
        expect(error).to be_a(PeerReview::ParentOverrideNotFoundError)
        expect(error.message).to include("course")
      end
    end

    it "uses I18n.t for error message" do
      expect(I18n).to receive(:t).with(
        "Parent assignment Course override not found for course %{course_id}",
        { course_id: }
      ).and_call_original

      expect { service.validate_course_parent_override_exists(nil, course_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "raises error when parent override is false" do
      expect { service.validate_course_parent_override_exists(false, course_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "handles numeric course IDs" do
      expect { service.validate_course_parent_override_exists(nil, 12_345) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /course/
      )
    end
  end

  describe "#validate_group_parent_override_exists" do
    let(:group_category) { course.group_categories.create!(name: "Project Groups") }
    let(:group) { group_category.groups.create!(context: course, name: "Group 1") }
    let(:group_id) { group.id }
    let(:mock_parent_override) { double("parent_override") }

    it "does not raise an error when parent override is present" do
      expect { service.validate_group_parent_override_exists(mock_parent_override, group_id) }.not_to raise_error
    end

    it "raises ParentOverrideNotFoundError when parent override is nil" do
      expect { service.validate_group_parent_override_exists(nil, group_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /Parent assignment Group override not found for group/
      )
    end

    it "includes group ID in error message" do
      expect { service.validate_group_parent_override_exists(nil, group_id) }.to raise_error do |error|
        expect(error).to be_a(PeerReview::ParentOverrideNotFoundError)
        expect(error.message).to include("group")
      end
    end

    it "uses I18n.t for error message" do
      expect(I18n).to receive(:t).with(
        "Parent assignment Group override not found for group %{group_id}",
        { group_id: }
      ).and_call_original

      expect { service.validate_group_parent_override_exists(nil, group_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "raises error when parent override is false" do
      expect { service.validate_group_parent_override_exists(false, group_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "handles numeric group IDs" do
      expect { service.validate_group_parent_override_exists(nil, 54_321) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /group/
      )
    end
  end

  describe "#validate_section_parent_override_exists" do
    let(:section) { add_section("Test Section", course:) }
    let(:section_id) { section.id }
    let(:mock_parent_override) { double("parent_override") }

    it "does not raise an error when parent override is present" do
      expect { service.validate_section_parent_override_exists(mock_parent_override, section_id) }.not_to raise_error
    end

    it "raises ParentOverrideNotFoundError when parent override is nil" do
      expect { service.validate_section_parent_override_exists(nil, section_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /Parent assignment Section override not found for section/
      )
    end

    it "includes section ID in error message" do
      expect { service.validate_section_parent_override_exists(nil, section_id) }.to raise_error do |error|
        expect(error).to be_a(PeerReview::ParentOverrideNotFoundError)
        expect(error.message).to include("section")
      end
    end

    it "uses I18n.t for error message" do
      expect(I18n).to receive(:t).with(
        "Parent assignment Section override not found for section %{section_id}",
        { section_id: }
      ).and_call_original

      expect { service.validate_section_parent_override_exists(nil, section_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "raises error when parent override is false" do
      expect { service.validate_section_parent_override_exists(false, section_id) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError
      )
    end

    it "handles numeric section IDs" do
      expect { service.validate_section_parent_override_exists(nil, 99_999) }.to raise_error(
        PeerReview::ParentOverrideNotFoundError,
        /section/
      )
    end
  end

  describe "#validate_override_dates_against_parent_override" do
    let(:parent_override) do
      double(
        "parent_override",
        unlock_at: 1.day.from_now,
        unlock_at_overridden: true,
        lock_at: 2.weeks.from_now,
        lock_at_overridden: true,
        assignment: parent_assignment
      )
    end

    context "with valid date combinations" do
      it "does not raise an error when peer review dates are within parent override dates" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "does not raise an error when peer review unlock_at equals parent unlock_at" do
        peer_review_override = {
          unlock_at: parent_override.unlock_at,
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "does not raise an error when peer review lock_at equals parent lock_at" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: parent_override.lock_at
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "does not raise an error when peer review due_at is at parent lock_at" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: parent_override.lock_at,
          lock_at: parent_override.lock_at
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "does not raise an error when some peer review dates are nil" do
        peer_review_override = {
          due_at: 1.week.from_now,
          unlock_at: nil,
          lock_at: nil
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "does not raise an error when all peer review dates are nil" do
        peer_review_override = {
          due_at: nil,
          unlock_at: nil,
          lock_at: nil
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end
    end

    context "when parent override has no unlock_at" do
      let(:parent_assignment_no_unlock) do
        assignment_model(
          course:,
          title: "Assignment without unlock",
          unlock_at: nil,
          lock_at: 2.weeks.from_now,
          peer_reviews: true
        )
      end
      let(:parent_override_no_unlock) do
        double(
          "parent_override",
          unlock_at: nil,
          unlock_at_overridden: false,
          lock_at: 2.weeks.from_now,
          lock_at_overridden: true,
          assignment: parent_assignment_no_unlock
        )
      end

      it "does not validate against parent unlock_at" do
        peer_review_override = {
          unlock_at: 1.day.ago,
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_no_unlock) }.not_to raise_error
      end
    end

    context "when parent override has no lock_at" do
      let(:parent_assignment_no_lock) do
        assignment_model(
          course:,
          title: "Assignment without lock",
          due_at: 2.weeks.from_now,
          unlock_at: 1.day.from_now,
          lock_at: nil,
          peer_reviews: true
        )
      end
      let(:parent_override_no_lock) do
        double(
          "parent_override",
          unlock_at: 1.day.from_now,
          unlock_at_overridden: true,
          lock_at: nil,
          lock_at_overridden: false,
          assignment: parent_assignment_no_lock
        )
      end

      it "does not validate against parent lock_at" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_no_lock) }.not_to raise_error
      end
    end

    context "with invalid date combinations" do
      it "raises an error when peer review unlock_at is before parent unlock_at" do
        peer_review_override = {
          unlock_at: 1.hour.from_now,
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Peer review override unlock date cannot be before parent override unlock date/
        )
      end

      it "raises an error when peer review due_at is before parent unlock_at" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.hour.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Peer review override due date cannot be before parent override unlock date/
        )
      end

      it "raises an error when peer review due_at is after parent lock_at" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 3.weeks.from_now,
          lock_at: 4.weeks.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Peer review override due date cannot be after parent override lock date/
        )
      end

      it "raises an error when peer review lock_at is after parent lock_at" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: 3.weeks.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Peer review override lock date cannot be after parent override lock date/
        )
      end
    end

    context "with string date values" do
      it "handles string dates correctly" do
        base_time = Time.zone.now
        peer_review_override = {
          unlock_at: (base_time + 2.days).iso8601,
          due_at: (base_time + 1.week).iso8601,
          lock_at: (base_time + 10.days).iso8601
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "raises error when string dates violate parent constraints" do
        base_time = Time.zone.now
        parent_override_with_dates = double(
          "parent_override",
          unlock_at: base_time + 1.day,
          unlock_at_overridden: true,
          lock_at: base_time + 2.weeks,
          lock_at_overridden: true,
          assignment: parent_assignment
        )
        peer_review_override = {
          unlock_at: (base_time + 1.hour).iso8601,
          due_at: (base_time + 1.week).iso8601,
          lock_at: (base_time + 10.days).iso8601
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Peer review override unlock date cannot be before parent override unlock date/
        )
      end

      it "handles mixed Time objects and string dates correctly" do
        base_time = Time.zone.now
        peer_review_override = {
          unlock_at: base_time + 2.days,
          due_at: (base_time + 1.week).iso8601,
          lock_at: base_time + 10.days
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end
    end

    context "with invalid date format validation" do
      it "raises an error for invalid unlock_at date format" do
        peer_review_override = {
          unlock_at: "invalid_date",
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Invalid date format for unlock_at/
        )
      end

      it "raises an error for invalid due_at date format" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: "bad_date",
          lock_at: 10.days.from_now
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Invalid date format for due_at/
        )
      end

      it "raises an error for invalid lock_at date format" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: "invalid_date"
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError,
          /Invalid date format for lock_at/
        )
      end

      it "does not raise format error for nil date values" do
        peer_review_override = {
          unlock_at: nil,
          due_at: nil,
          lock_at: nil
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "does not raise format error for empty string values" do
        peer_review_override = {
          unlock_at: "",
          due_at: "",
          lock_at: ""
        }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end
    end

    context "error message internationalization" do
      it "calls I18n.t for unlock_at before parent unlock_at error" do
        peer_review_override = {
          unlock_at: 1.hour.from_now,
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect(I18n).to receive(:t).with("Peer review override unlock date cannot be before parent override unlock date").and_call_original

        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError
        )
      end

      it "calls I18n.t for due_at before parent unlock_at error" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.hour.from_now,
          lock_at: 10.days.from_now
        }
        expect(I18n).to receive(:t).with("Peer review override due date cannot be before parent override unlock date").and_call_original

        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError
        )
      end

      it "calls I18n.t for due_at after parent lock_at error" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 3.weeks.from_now,
          lock_at: 4.weeks.from_now
        }
        expect(I18n).to receive(:t).with("Peer review override due date cannot be after parent override lock date").and_call_original

        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError
        )
      end

      it "calls I18n.t for lock_at after parent lock_at error" do
        peer_review_override = {
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: 3.weeks.from_now
        }
        expect(I18n).to receive(:t).with("Peer review override lock date cannot be after parent override lock date").and_call_original

        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError
        )
      end

      it "calls I18n.t for invalid date format error" do
        peer_review_override = {
          unlock_at: "invalid_date",
          due_at: 1.week.from_now,
          lock_at: 10.days.from_now
        }
        expect(I18n).to receive(:t).with(
          "Invalid date format for %{field}: %{value}",
          { field: :unlock_at, value: "invalid_date" }
        ).and_call_original

        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.to raise_error(
          PeerReview::InvalidDatesError
        )
      end
    end

    context "edge cases" do
      it "handles empty peer review override hash" do
        peer_review_override = {}
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "handles peer review override with only unlock_at" do
        peer_review_override = { unlock_at: 2.days.from_now }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "handles peer review override with only due_at" do
        peer_review_override = { due_at: 1.week.from_now }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end

      it "handles peer review override with only lock_at" do
        peer_review_override = { lock_at: 10.days.from_now }
        expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override) }.not_to raise_error
      end
    end

    context "time precision validation" do
      let(:base_time) { Time.zone.parse("2025-01-15 14:30:00") }

      context "when validating unlock_at with time precision" do
        let(:parent_override_with_time) do
          double(
            "parent_override",
            unlock_at: base_time,
            unlock_at_overridden: true,
            lock_at: base_time + 2.weeks,
            lock_at_overridden: true,
            assignment: parent_assignment
          )
        end

        it "allows peer review unlock_at at exact same time as parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "allows peer review unlock_at 1 second after parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.second,
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "raises error when peer review unlock_at is 1 second before parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time - 1.second,
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end

        it "raises error when peer review unlock_at is 1 minute before parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time - 1.minute,
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end

        it "raises error when dates match but time is earlier" do
          peer_review_override = {
            unlock_at: Time.zone.parse("2025-01-15 14:29:59"),
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end
      end

      context "when validating due_at with time precision" do
        let(:parent_override_with_time) do
          double(
            "parent_override",
            unlock_at: base_time,
            unlock_at_overridden: true,
            lock_at: base_time + 2.weeks,
            lock_at_overridden: true,
            assignment: parent_assignment
          )
        end

        it "allows peer review due_at at exact same time as parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "allows peer review due_at 1 second after parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time + 1.second,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "validates unlock_at first when both unlock_at and due_at are before parent unlock_at" do
          parent_override_late_unlock = double(
            "parent_override",
            unlock_at: base_time + 1.week,
            unlock_at_overridden: true,
            lock_at: base_time + 3.weeks,
            lock_at_overridden: true,
            assignment: parent_assignment
          )
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time + 1.week - 1.second,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_late_unlock) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end
      end

      context "when validating lock_at with time precision" do
        let(:parent_override_with_time) do
          double(
            "parent_override",
            unlock_at: base_time,
            unlock_at_overridden: true,
            lock_at: base_time + 2.weeks,
            lock_at_overridden: true,
            assignment: parent_assignment
          )
        end

        it "allows peer review lock_at at exact same time as parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "allows peer review lock_at 1 second before parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks - 1.second
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "raises error when peer review lock_at is 1 second after parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks + 1.second
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end

        it "raises error when peer review lock_at is 1 minute after parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks + 1.minute
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end

        it "raises error when dates match but time is later" do
          parent_lock_time = Time.zone.parse("2025-01-29 14:30:00")
          parent_override_late = double(
            "parent_override",
            unlock_at: base_time,
            unlock_at_overridden: true,
            lock_at: parent_lock_time,
            lock_at_overridden: true,
            assignment: parent_assignment
          )
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: Time.zone.parse("2025-01-29 14:30:01")
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_late) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end
      end

      context "when validating due_at against lock_at with time precision" do
        let(:parent_override_with_time) do
          double(
            "parent_override",
            unlock_at: base_time,
            unlock_at_overridden: true,
            lock_at: base_time + 1.week,
            lock_at_overridden: true,
            assignment: parent_assignment
          )
        end

        it "allows peer review due_at at exact same time as parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 1.week
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "allows peer review due_at 1 second before parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week - 1.second,
            lock_at: base_time + 1.week
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.not_to raise_error
        end

        it "raises error when peer review due_at is 1 second after parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week + 1.second,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_time) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override due date cannot be after parent override lock date/
          )
        end
      end

      context "with timezone considerations" do
        it "correctly compares times across different time representations" do
          utc_time = Time.utc(2025, 1, 15, 14, 30, 0)
          pacific_time = Time.find_zone("America/Los_Angeles").parse("2025-01-15 06:30:00")

          parent_override_utc = double(
            "parent_override",
            unlock_at: utc_time,
            unlock_at_overridden: true,
            lock_at: utc_time + 2.weeks,
            lock_at_overridden: true,
            assignment: parent_assignment
          )

          peer_review_override = {
            unlock_at: pacific_time,
            due_at: pacific_time + 1.week,
            lock_at: pacific_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_utc) }.not_to raise_error
        end
      end
    end

    context "when parent override with unlock_at_overridden" do
      context "when unlock_at_overridden is false but unlock_at has a value" do
        let(:parent_assignment_with_unlock) do
          assignment_model(
            course:,
            title: "Assignment with unlock",
            due_at: 2.weeks.from_now,
            unlock_at: 3.days.from_now,
            lock_at: 3.weeks.from_now,
            peer_reviews: true
          )
        end
        let(:parent_override_with_flag_false) do
          double(
            "parent_override",
            unlock_at: 2.days.from_now,
            unlock_at_overridden: false,
            lock_at: 2.weeks.from_now,
            lock_at_overridden: true,
            assignment: parent_assignment_with_unlock
          )
        end

        it "skips unlock_at validation when unlock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 10.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.not_to raise_error
        end

        it "validates against assignment unlock_at when unlock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 4.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 10.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.not_to raise_error
        end

        it "skips due_at validation against unlock_at when unlock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 4.days.from_now,
            due_at: 2.days.from_now,
            lock_at: 10.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.not_to raise_error
        end

        it "still validates lock_at" do
          peer_review_override = {
            unlock_at: 4.days.from_now,
            due_at: 3.weeks.from_now,
            lock_at: 4.weeks.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override due date cannot be after parent override lock date/
          )
        end
      end

      context "when lock_at_overridden is false but lock_at has a value" do
        let(:parent_assignment_with_lock) do
          assignment_model(
            course:,
            title: "Assignment with lock",
            due_at: 1.week.from_now,
            unlock_at: 1.day.from_now,
            lock_at: 10.days.from_now,
            peer_reviews: true
          )
        end
        let(:parent_override_with_flag_false) do
          double(
            "parent_override",
            unlock_at: 1.day.from_now,
            unlock_at_overridden: true,
            lock_at: 2.weeks.from_now,
            lock_at_overridden: false,
            assignment: parent_assignment_with_lock
          )
        end

        it "skips lock_at validation when lock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 2.days.from_now,
            due_at: 11.days.from_now,
            lock_at: 12.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.not_to raise_error
        end

        it "validates against assignment lock_at when lock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 9.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.not_to raise_error
        end

        it "skips peer review lock_at validation when lock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 11.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.not_to raise_error
        end

        it "still validates unlock_at" do
          peer_review_override = {
            unlock_at: 1.hour.from_now,
            due_at: 1.week.from_now,
            lock_at: 9.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_flag_false) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end
      end

      context "when both unlock_at_overridden and lock_at_overridden are false but dates have values" do
        let(:parent_assignment_with_both_dates) do
          assignment_model(
            course:,
            title: "Assignment with both dates",
            due_at: 10.days.from_now,
            unlock_at: 5.days.from_now,
            lock_at: 15.days.from_now,
            peer_reviews: true
          )
        end
        let(:parent_override_both_flags_false) do
          double(
            "parent_override",
            unlock_at: 2.days.from_now,
            unlock_at_overridden: false,
            lock_at: 2.weeks.from_now,
            lock_at_overridden: false,
            assignment: parent_assignment_with_both_dates
          )
        end

        it "skips unlock_at validation when unlock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 4.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 10.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_both_flags_false) }.not_to raise_error
        end

        it "skips lock_at validation when lock_at_overridden is false" do
          peer_review_override = {
            unlock_at: 6.days.from_now,
            due_at: 16.days.from_now,
            lock_at: 17.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_both_flags_false) }.not_to raise_error
        end

        it "validates peer review dates within assignment date range" do
          peer_review_override = {
            unlock_at: 6.days.from_now,
            due_at: 10.days.from_now,
            lock_at: 14.days.from_now
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_both_flags_false) }.not_to raise_error
        end
      end
    end

    context "boundary conditions with exact date equality" do
      let(:base_time) { Time.zone.parse("2025-01-15 12:00:00") }
      let(:parent_override_with_dates) do
        double(
          "parent_override",
          unlock_at: base_time,
          unlock_at_overridden: true,
          lock_at: base_time + 2.weeks,
          lock_at_overridden: true,
          assignment: parent_assignment
        )
      end

      context "when peer review unlock_at equals parent unlock_at exactly" do
        it "does not raise an error" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end

        it "allows peer review due_at to also equal parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end
      end

      context "when peer review lock_at equals parent lock_at exactly" do
        it "does not raise an error" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end

        it "allows peer review due_at to also equal parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 2.weeks,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end
      end

      context "when all peer review dates equal parent boundaries" do
        it "does not raise an error when unlock_at and lock_at match parent boundaries" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end

        it "does not raise an error when all dates are at unlock boundary" do
          peer_review_override = {
            unlock_at: base_time,
            due_at: base_time,
            lock_at: base_time
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end

        it "does not raise an error when all dates are at lock boundary" do
          peer_review_override = {
            unlock_at: base_time + 2.weeks,
            due_at: base_time + 2.weeks,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end
      end

      context "when peer review dates are just outside boundaries" do
        it "raises error when unlock_at is a second before parent unlock_at" do
          peer_review_override = {
            unlock_at: base_time - 1.second,
            due_at: base_time + 1.week,
            lock_at: base_time + 10.days
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end

        it "raises error when lock_at is a second after parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 1.week,
            lock_at: base_time + 2.weeks + 1.second
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end

        it "raises error when due_at is a second after parent lock_at" do
          peer_review_override = {
            unlock_at: base_time + 1.day,
            due_at: base_time + 2.weeks + 1.second,
            lock_at: base_time + 2.weeks
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override due date cannot be after parent override lock date/
          )
        end
      end

      context "comparing boundaries with string date formats" do
        it "allows peer review dates when string format equals parent boundaries" do
          peer_review_override = {
            unlock_at: base_time.iso8601,
            due_at: (base_time + 1.week).iso8601,
            lock_at: (base_time + 2.weeks).iso8601
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.not_to raise_error
        end

        it "raises error when string format is slightly before parent unlock_at" do
          peer_review_override = {
            unlock_at: (base_time - 1.second).iso8601,
            due_at: (base_time + 1.week).iso8601,
            lock_at: (base_time + 10.days).iso8601
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end

        it "raises error when string format is slightly after parent lock_at" do
          peer_review_override = {
            unlock_at: (base_time + 1.day).iso8601,
            due_at: (base_time + 1.week).iso8601,
            lock_at: (base_time + 2.weeks + 1.second).iso8601
          }
          expect { service.validate_override_dates_against_parent_override(peer_review_override, parent_override_with_dates) }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end
      end
    end
  end

  describe "integration with module inclusion" do
    it "includes the validation methods in the service class" do
      expect(service).to respond_to(:validate_parent_assignment)
      expect(service).to respond_to(:validate_peer_reviews_enabled)
      expect(service).to respond_to(:validate_feature_enabled)
      expect(service).to respond_to(:validate_assignment_submission_types)
      expect(service).to respond_to(:validate_peer_review_sub_assignment_exists)
      expect(service).to respond_to(:validate_peer_review_sub_assignment_not_exist)
      expect(service).to respond_to(:validate_override_exists)
      expect(service).to respond_to(:validate_set_type_required)
      expect(service).to respond_to(:validate_set_type_supported)
      expect(service).to respond_to(:validate_set_id_required)
      expect(service).to respond_to(:validate_section_exists)
      expect(service).to respond_to(:validate_student_ids_required)
      expect(service).to respond_to(:validate_group_assignment_required)
      expect(service).to respond_to(:validate_group_exists)
      expect(service).to respond_to(:validate_adhoc_parent_override_exists)
      expect(service).to respond_to(:validate_course_parent_override_exists)
      expect(service).to respond_to(:validate_group_parent_override_exists)
      expect(service).to respond_to(:validate_section_parent_override_exists)
      expect(service).to respond_to(:validate_override_dates_against_parent_override)
    end

    it "properly accesses instance variables set in the including class" do
      expect(service.instance_variable_get(:@parent_assignment)).to eq(parent_assignment)
      expect(service.instance_variable_get(:@peer_review_overrides)).to eq([])
    end
  end
end

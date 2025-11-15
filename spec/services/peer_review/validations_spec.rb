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
    course.enable_feature!(:peer_review_grading)
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
      course.disable_feature!(:peer_review_grading)
      expect { service.validate_feature_enabled(parent_assignment) }.to raise_error(
        PeerReview::FeatureDisabledError,
        "Peer Review Grading feature flag is disabled"
      )
    end

    it "raises an error when feature is not available for the context" do
      allow(parent_assignment.context).to receive(:feature_enabled?).with(:peer_review_grading).and_return(false)
      expect { service.validate_feature_enabled(parent_assignment) }.to raise_error(
        PeerReview::FeatureDisabledError,
        "Peer Review Grading feature flag is disabled"
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

  describe "#validate_override_dates" do
    context "with valid date combinations" do
      it "does not raise an error when all dates are in correct order" do
        override_params = {
          due_at: 3.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 1.week.from_now
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when only due_at is provided" do
        override_params = { due_at: 3.days.from_now }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when only unlock_at is provided" do
        override_params = { unlock_at: 1.day.from_now }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when only lock_at is provided" do
        override_params = { lock_at: 1.week.from_now }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when due_at equals unlock_at" do
        same_time = 2.days.from_now
        override_params = {
          due_at: same_time,
          unlock_at: same_time
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when due_at equals lock_at" do
        same_time = 2.days.from_now
        override_params = {
          due_at: same_time,
          lock_at: same_time
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when unlock_at equals lock_at" do
        same_time = 2.days.from_now
        override_params = {
          unlock_at: same_time,
          lock_at: same_time
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end
    end

    context "with invalid date combinations" do
      it "raises an error when due date is before unlock date" do
        override_params = {
          due_at: 1.day.from_now,
          unlock_at: 2.days.from_now
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Due date cannot be before unlock date"
        )
      end

      it "raises an error when due date is after lock date" do
        override_params = {
          due_at: 1.week.from_now,
          lock_at: 3.days.from_now
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Due date cannot be after lock date"
        )
      end

      it "raises an error when unlock date is after lock date" do
        override_params = {
          unlock_at: 1.week.from_now,
          lock_at: 3.days.from_now
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Unlock date cannot be after lock date"
        )
      end

      it "raises error for multiple invalid conditions with due_at before unlock_at taking precedence" do
        override_params = {
          due_at: 1.day.from_now,
          unlock_at: 2.days.from_now,
          lock_at: 3.hours.from_now
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Due date cannot be before unlock date"
        )
      end
    end

    context "with nil date values" do
      it "does not raise an error when all dates are nil" do
        override_params = {
          due_at: nil,
          unlock_at: nil,
          lock_at: nil
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise an error when some dates are nil" do
        override_params = {
          due_at: 2.days.from_now,
          unlock_at: nil,
          lock_at: 1.week.from_now
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "handles empty hash" do
        override_params = {}
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end
    end

    context "with string date values" do
      it "handles string dates correctly" do
        base_time = Time.zone.now
        override_params = {
          due_at: (base_time + 3.days).iso8601,
          unlock_at: (base_time + 1.day).iso8601,
          lock_at: (base_time + 1.week).iso8601
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "raises error when string dates are in wrong order" do
        base_time = Time.zone.now
        override_params = {
          due_at: (base_time + 1.day).iso8601,
          unlock_at: (base_time + 2.days).iso8601
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Due date cannot be before unlock date"
        )
      end

      it "handles mixed Time objects and string dates correctly" do
        base_time = Time.zone.now
        override_params = {
          due_at: base_time + 3.days, # Time object
          unlock_at: (base_time + 1.day).iso8601, # String
          lock_at: base_time + 1.week # Time object
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "validates string format even when mixed with Time objects" do
        override_params = {
          due_at: 3.days.from_now, # Time object
          unlock_at: "invalid_date" # Invalid string
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Invalid datetime format for unlock_at"
        )
      end
    end

    context "with invalid date format validation" do
      it "does not raise an error for valid ISO8601 date strings" do
        override_params = {
          due_at: "2025-10-10T12:00:00-06:00",
          unlock_at: "2025-10-01T10:00:00-06:00",
          lock_at: "2025-10-15T23:59:59-06:00"
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "raises an error for invalid due_at date format" do
        override_params = { due_at: "2025-10-01" }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Invalid datetime format for due_at"
        )
      end

      it "raises an error for invalid unlock_at date format" do
        override_params = { unlock_at: "10/01/2025" }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Invalid datetime format for unlock_at"
        )
      end

      it "raises an error for invalid lock_at date format" do
        override_params = { lock_at: "bad_date" }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Invalid datetime format for lock_at"
        )
      end

      it "raises format error before date relationship validation" do
        override_params = {
          due_at: "invalid_date",
          unlock_at: "2025-10-15T12:00:00-06:00"
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
          "Invalid datetime format for due_at"
        )
      end

      it "does not raise format error for nil date values" do
        override_params = {
          due_at: nil,
          unlock_at: nil,
          lock_at: nil
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise format error for Time objects" do
        override_params = {
          due_at: 3.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 1.week.from_now
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "does not raise format error for empty string values" do
        override_params = {
          due_at: "",
          unlock_at: "",
          lock_at: ""
        }
        expect { service.validate_override_dates(override_params) }.not_to raise_error
      end

      it "raises error for multiple invalid date formats, checking due_at first" do
        override_params = {
          due_at: "invalid_date",
          unlock_at: "also_invalid",
          lock_at: "bad_format"
        }
        expect { service.validate_override_dates(override_params) }.to raise_error(
          PeerReview::InvalidOverrideDatesError,
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
      course.disable_feature!(:peer_review_grading)
      expect(I18n).to receive(:t).with("Peer Review Grading feature flag is disabled").and_call_original

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

    it "calls I18n.t for invalid override dates errors" do
      override_params = {
        due_at: 1.day.from_now,
        unlock_at: 2.days.from_now
      }
      expect(I18n).to receive(:t).with("Due date cannot be before unlock date").and_call_original

      expect { service.validate_override_dates(override_params) }.to raise_error(
        PeerReview::InvalidOverrideDatesError
      )
    end

    it "calls I18n.t for invalid date format errors" do
      override_params = { due_at: "invalid_date" }
      expect(I18n).to receive(:t).with("Invalid datetime format for %{attribute}", { attribute: "due_at" }).and_call_original

      expect { service.validate_override_dates(override_params) }.to raise_error(
        PeerReview::InvalidOverrideDatesError
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
    end

    it "properly accesses instance variables set in the including class" do
      expect(service.instance_variable_get(:@parent_assignment)).to eq(parent_assignment)
      expect(service.instance_variable_get(:@peer_review_overrides)).to eq([])
    end
  end
end

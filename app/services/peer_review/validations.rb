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

module PeerReview::Validations
  require_relative "peer_review_error"

  def validate_parent_assignment(assignment)
    unless assignment.present? && assignment.is_a?(Assignment) && assignment.persisted?
      raise PeerReview::InvalidParentAssignmentError, I18n.t("Invalid parent assignment")
    end
  end

  def validate_peer_reviews_enabled(assignment)
    unless assignment.peer_reviews?
      raise PeerReview::PeerReviewsNotEnabledError, I18n.t("Peer reviews are not enabled for this assignment")
    end
  end

  def validate_feature_enabled(assignment)
    unless assignment.context.feature_enabled?(:peer_review_allocation_and_grading)
      raise PeerReview::FeatureDisabledError, I18n.t("Peer Review Allocation and Grading feature flag is disabled")
    end
  end

  def validate_assignment_submission_types(assignment)
    if assignment.external_tool?
      raise PeerReview::InvalidAssignmentSubmissionTypesError, I18n.t("Peer reviews cannot be used with External Tool assignments")
    end

    if assignment.submission_types == "discussion_topic"
      raise PeerReview::InvalidAssignmentSubmissionTypesError, I18n.t("Peer reviews cannot be used with Discussion Topic assignments")
    end
  end

  def validate_peer_review_sub_assignment_exists(assignment)
    if assignment.peer_review_sub_assignment.blank?
      raise PeerReview::SubAssignmentNotExistError, I18n.t("Peer review sub assignment does not exist")
    end
  end

  def validate_peer_review_sub_assignment_not_exist(assignment)
    if assignment.peer_review_sub_assignment.present?
      raise PeerReview::SubAssignmentExistsError, I18n.t("Peer review sub assignment exists")
    end
  end

  # Validates that peer review dates follow the restriction below
  # peer review unlock_at < peer review due_at <= peer review lock_at
  def validate_peer_review_dates(peer_review_dates)
    parsed_dates = {}

    %w[due_at unlock_at lock_at].each do |date_field|
      date_value = peer_review_dates.fetch(date_field.to_sym, nil)
      next unless date_value.present?

      # Accept both Time objects and ISO8601 strings for API compatibility
      if date_value.is_a?(String)
        unless Api::ISO8601_REGEX.match?(date_value)
          raise PeerReview::InvalidDatesError, I18n.t("Invalid datetime format for %{attribute}", attribute: date_field)
        end

        parsed_dates[date_field.to_sym] = Time.zone.parse(date_value)
      else
        parsed_dates[date_field.to_sym] = date_value
      end
    end

    due_at = parsed_dates[:due_at]
    unlock_at = parsed_dates[:unlock_at]
    lock_at = parsed_dates[:lock_at]

    if due_at && unlock_at && due_at < unlock_at
      raise PeerReview::InvalidDatesError, I18n.t("Due date cannot be before unlock date")
    end

    if due_at && lock_at && due_at > lock_at
      raise PeerReview::InvalidDatesError, I18n.t("Due date cannot be after lock date")
    end

    if unlock_at && lock_at && unlock_at > lock_at
      raise PeerReview::InvalidDatesError, I18n.t("Unlock date cannot be after lock date")
    end
  end

  # Validates that peer review override dates fall within parent assignment override dates
  # assignment available from date <= assignment due date <= peer review available from date <= peer review due date <= peer review until date <= assignment until date
  def validate_override_dates_against_parent_override(peer_review_override, parent_override)
    parent_unlock_at = parent_override.unlock_at_overridden ? parent_override.unlock_at : nil
    parent_due_at = parent_override.due_at_overridden ? parent_override.due_at : nil
    parent_lock_at = parent_override.lock_at_overridden ? parent_override.lock_at : nil

    validate_dates_within_parent_boundaries(
      child_dates: peer_review_override,
      parent_unlock_at:,
      parent_due_at:,
      parent_lock_at:,
      is_override: true
    )
  end

  def validate_peer_review_dates_against_parent_assignment(peer_review_dates, parent_assignment)
    validate_peer_review_dates(peer_review_dates)

    validate_dates_within_parent_boundaries(
      child_dates: peer_review_dates,
      parent_unlock_at: parent_assignment.unlock_at,
      parent_due_at: parent_assignment.due_at,
      parent_lock_at: parent_assignment.lock_at,
      is_override: false
    )
  end

  def parse_date(dates_hash, field)
    date_value = dates_hash.fetch(field, nil)
    return nil unless date_value.present?

    if date_value.is_a?(String)
      parsed = Time.zone.parse(date_value)
      if parsed.nil?
        raise PeerReview::InvalidDatesError,
              I18n.t("Invalid date format for %{field}: %{value}", field:, value: date_value)
      end
      parsed
    else
      date_value
    end
  end

  def validate_dates_within_parent_boundaries(child_dates:, parent_unlock_at:, parent_due_at:, parent_lock_at:, is_override: false)
    child_unlock_at = parse_date(child_dates, :unlock_at)
    child_due_at = parse_date(child_dates, :due_at)
    child_lock_at = parse_date(child_dates, :lock_at)

    # Validate: parent unlock_at <= parent due_at
    if parent_unlock_at && parent_due_at && parent_unlock_at > parent_due_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Parent override due date cannot be before parent override unlock date") : I18n.t("Assignment due date cannot be before assignment unlock date")
    end

    # Validate: child unlock_at constraint
    # If parent_due_at is present, validate: parent due_at <= child unlock_at
    # Otherwise, fall back to: parent unlock_at <= child unlock_at
    if parent_due_at && child_unlock_at && parent_due_at > child_unlock_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Peer review override unlock date cannot be before parent override due date") : I18n.t("Peer review unlock date cannot be before assignment due date")
    elsif !parent_due_at && parent_unlock_at && child_unlock_at && parent_unlock_at > child_unlock_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Peer review override unlock date cannot be before parent override unlock date") : I18n.t("Peer review unlock date cannot be before assignment unlock date")
    end

    # Validate: parent unlock_at <= child due_at (for backward compatibility)
    if parent_unlock_at && child_due_at && parent_unlock_at > child_due_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Peer review override due date cannot be before parent override unlock date") : I18n.t("Peer review due date cannot be before assignment unlock date")
    end

    # Validate: parent due_at <= child due_at
    if parent_due_at && child_due_at && parent_due_at > child_due_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Peer review override due date cannot be before parent override due date") : I18n.t("Peer review due date cannot be before assignment due date")
    end

    # Validate: child due_at <= parent lock_at
    if child_due_at && parent_lock_at && child_due_at > parent_lock_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Peer review override due date cannot be after parent override lock date") : I18n.t("Peer review due date cannot be after assignment lock date")
    end

    # Validate: child lock_at <= parent lock_at
    if child_lock_at && parent_lock_at && child_lock_at > parent_lock_at
      raise PeerReview::InvalidDatesError,
            is_override ? I18n.t("Peer review override lock date cannot be after parent override lock date") : I18n.t("Peer review lock date cannot be after assignment lock date")
    end
  end

  def validate_set_type_required(set_type)
    raise PeerReview::SetTypeRequiredError, I18n.t("Set type is required") unless set_type.present?
  end

  def validate_set_id_required(set_id)
    raise PeerReview::SetIdRequiredError, I18n.t("Set id is required") unless set_id.present?
  end

  def validate_override_exists(override)
    raise PeerReview::OverrideNotFoundError, I18n.t("Override does not exist") unless override.present?
  end

  def validate_section_exists(section)
    raise PeerReview::SectionNotFoundError, I18n.t("Section does not exist") unless section.present?
  end

  def validate_course_exists(course)
    raise PeerReview::CourseNotFoundError, I18n.t("Course does not exist") unless course.present?
  end

  def validate_student_ids_required(student_ids)
    if student_ids.nil? || student_ids == "" || student_ids.to_s.strip.empty? || (student_ids.is_a?(Array) && student_ids.empty?)
      raise PeerReview::StudentIdsRequiredError, I18n.t("Student ids are required")
    end
  end

  def validate_student_ids_in_course(student_ids)
    raise PeerReview::StudentIdsNotInCourseError, I18n.t("Student ids are not in course") if student_ids.blank?
  end

  def validate_set_type_supported(set_type, services)
    unless services.key?(set_type)
      supported_types = services.keys.join(", ")
      raise PeerReview::SetTypeNotSupportedError,
            I18n.t("Set type '%{set_type}' is not supported. Supported types are: %{supported_types}", set_type:, supported_types:)
    end
  end

  def validate_group_assignment_required(assignment)
    unless assignment.group_category_id
      raise PeerReview::GroupAssignmentRequiredError, I18n.t("Must be a group assignment to create group overrides")
    end
  end

  def validate_group_exists(group)
    raise PeerReview::GroupNotFoundError, I18n.t("Group does not exist") unless group.present?
  end

  def validate_adhoc_parent_override_exists(parent_override, student_ids)
    unless parent_override.present?
      raise PeerReview::ParentOverrideNotFoundError,
            I18n.t("Parent assignment ADHOC override not found for students %{student_ids}", student_ids: student_ids.join(", "))
    end
  end

  def validate_course_parent_override_exists(parent_override, course_id)
    unless parent_override.present?
      raise PeerReview::ParentOverrideNotFoundError,
            I18n.t("Parent assignment Course override not found for course %{course_id}", course_id:)
    end
  end

  def validate_group_parent_override_exists(parent_override, group_id)
    unless parent_override.present?
      raise PeerReview::ParentOverrideNotFoundError,
            I18n.t("Parent assignment Group override not found for group %{group_id}", group_id:)
    end
  end

  def validate_section_parent_override_exists(parent_override, section_id)
    unless parent_override.present?
      raise PeerReview::ParentOverrideNotFoundError,
            I18n.t("Parent assignment Section override not found for section %{section_id}", section_id:)
    end
  end
end

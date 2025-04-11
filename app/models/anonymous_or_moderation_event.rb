# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

class AnonymousOrModerationEvent < ApplicationRecord
  EVENT_TYPES = %w[
    assignment_created
    assignment_updated
    docviewer_area_created
    docviewer_area_deleted
    docviewer_area_updated
    docviewer_comment_created
    docviewer_comment_deleted
    docviewer_comment_updated
    docviewer_free_draw_created
    docviewer_free_draw_deleted
    docviewer_free_draw_updated
    docviewer_free_text_created
    docviewer_free_text_deleted
    docviewer_free_text_updated
    docviewer_highlight_created
    docviewer_highlight_deleted
    docviewer_highlight_updated
    docviewer_point_created
    docviewer_point_deleted
    docviewer_point_updated
    docviewer_strikeout_created
    docviewer_strikeout_deleted
    docviewer_strikeout_updated
    grades_posted
    provisional_grade_created
    provisional_grade_selected
    provisional_grade_updated
    rubric_created
    rubric_deleted
    rubric_updated
    submission_comment_created
    submission_comment_deleted
    submission_comment_updated
    submission_updated
  ].freeze
  SUBMISSION_ID_EXCLUDED_EVENT_TYPES = %w[
    assignment_created
    assignment_updated
    grades_posted
    rubric_created
    rubric_deleted
    rubric_updated
  ].freeze
  SUBMISSION_ID_REQUIRED_EVENT_TYPES = (EVENT_TYPES - SUBMISSION_ID_EXCLUDED_EVENT_TYPES).freeze

  belongs_to :assignment, class_name: "AbstractAssignment"
  belongs_to :user, optional: true
  belongs_to :submission
  belongs_to :canvadoc
  belongs_to :quiz, class_name: "Quizzes::Quiz", optional: true
  belongs_to :context_external_tool, optional: true

  validates :assignment_id, presence: true
  validates :submission_id, presence: true, if: lambda { |event|
    SUBMISSION_ID_REQUIRED_EVENT_TYPES.include?(event.event_type)
  }
  validates :submission_id, absence: true, unless: lambda { |event|
    SUBMISSION_ID_REQUIRED_EVENT_TYPES.include?(event.event_type)
  }
  validates :event_type, presence: true
  validates :event_type, inclusion: EVENT_TYPES
  validates :payload, presence: true

  validate :event_perpetrator

  with_options if: ->(e) { e.event_type == "assignment_created" } do
    validates :canvadoc_id, absence: true
  end

  with_options if: ->(e) { e.event_type == "assignment_updated" } do
    validates :canvadoc_id, absence: true
  end

  with_options if: ->(e) { e.event_type&.start_with?("docviewer") } do
    validates :canvadoc_id, presence: true
    validates :submission_id, presence: true
    validate :payload_annotation_body_present
  end

  with_options if: ->(e) { e.event_type == "grades_posted" } do
    validates :canvadoc_id, absence: true
  end

  with_options if: ->(e) { e.event_type == "provisional_grade_selected" } do
    validates :canvadoc_id, absence: true
    validates :submission_id, presence: true
    validate :payload_id_present
    validate :payload_student_id_present
  end

  def self.events_for_submission(assignment_id:, submission_id:)
    events_for_submissions([{ assignment_id:, submission_id: }])
  end

  def self.events_for_submissions(ids)
    query = nil
    grouped_ids = ids.group_by { |id_pair| id_pair[:assignment_id] }
                     .transform_values { |pairs| pairs.map { |pair| pair[:submission_id] } }

    grouped_ids.each do |assignment_id, submission_ids|
      condition = where(assignment_id:, submission_id: [nil, *submission_ids]).order(:created_at)
      query = query.nil? ? condition : query.or(condition)
    end

    query
  end

  EVENT_TYPES.each do |event_type|
    scope event_type, -> { where(event_type:) }
  end

  # Determines the user's role in relation to a submission and assignment for auditing purposes.
  #
  # WARNING: This method makes critical assumptions about authorization. It will default to
  # returning "grader" for any user who doesn't match the explicit conditions, WITHOUT
  # actually verifying if the user has grading permissions.
  #
  # Proper authorization checks MUST be performed before calling this method to ensure
  # the user actually has a valid role in this context.
  #
  # Example misuse case:
  #   course = Course.find(1)
  #   assignment = course.assignments.first
  #   submission1 = assignment.submissions.first
  #   submission2 = assignment.submissions.second
  #
  #   # This would incorrectly return "grader" for a student who has no grading permissions
  #   AnonymousOrModerationEvent.auditing_user_role(user: submission1.user,
  #                                                submission: submission2,
  #                                                assignment: assignment)
  #
  # @param user [User] The user whose role is being determined
  # @param submission [Submission] The submission being considered
  # @param assignment [Assignment] The assignment containing the submission
  # @return [String] One of: "student", "final_grader", "admin", or "grader"
  def self.auditing_user_role(user:, submission:, assignment:)
    if submission.user == user
      "student"
    elsif assignment.moderated_grading? && assignment.final_grader == user
      "final_grader"
    elsif assignment.course.account_membership_allows(user)
      "admin"
    else
      "grader"
    end
  end

  private

  %w[id student_id annotation_body].each do |key|
    define_method :"payload_#{key}_present" do
      if payload[key].blank?
        errors.add(:payload, "#{key} can't be blank")
      end
    end
  end

  def event_perpetrator
    id_count = [user_id, context_external_tool_id, quiz_id].compact.length
    if id_count > 1
      errors.add(:base, "may not have multiple perpetrator associations")
    elsif id_count < 1
      errors.add(:base, "must have one perpetrator association")
    end
  end
end

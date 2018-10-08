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

  belongs_to :assignment
  belongs_to :user
  belongs_to :submission
  belongs_to :canvadoc

  validates :assignment_id, presence: true
  validates :submission_id, presence: true, if: ->(event) {
    SUBMISSION_ID_REQUIRED_EVENT_TYPES.include?(event.event_type)
  }
  validates :submission_id, absence: true, unless: -> (event) {
    SUBMISSION_ID_REQUIRED_EVENT_TYPES.include?(event.event_type)
  }
  validates :user_id, presence: true
  validates :event_type, presence: true
  validates :event_type, inclusion: EVENT_TYPES
  validates :payload, presence: true

  with_options if: ->(e) { e.event_type == "assignment_created" } do
    validates :canvadoc_id, absence: true
  end

  with_options if: ->(e) { e.event_type == "assignment_updated" } do
    validates :canvadoc_id, absence: true
  end

  with_options if: ->(e) { e.event_type&.start_with?('docviewer') } do
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
    self.where(assignment_id: assignment_id, submission_id: [nil, submission_id]).order(:created_at)
  end

  EVENT_TYPES.each do |event_type|
    scope event_type, -> { where(event_type: event_type) }
  end

  private

  %w[id student_id annotation_body].each do |key|
    define_method "payload_#{key}_present" do
      if payload[key].blank?
        errors.add(:payload, "#{key} can't be blank")
      end
    end
  end
end

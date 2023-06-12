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

class ObserverAlertThreshold < ActiveRecord::Base
  belongs_to :student, class_name: "User", inverse_of: :as_student_observer_alert_thresholds, foreign_key: :user_id
  belongs_to :observer, class_name: "User", inverse_of: :as_observer_observer_alert_thresholds
  has_many :observer_alerts, inverse_of: :observer_alert_threshold

  ALERT_TYPES_WITH_THRESHOLD = %w[
    assignment_grade_high
    assignment_grade_low
    course_grade_high
    course_grade_low
  ].freeze

  ALERT_TYPES_WITHOUT_THRESHOLD = %w[
    assignment_missing
    course_announcement
    institution_announcement
  ].freeze

  ALERT_TYPES = (ALERT_TYPES_WITH_THRESHOLD | ALERT_TYPES_WITHOUT_THRESHOLD).freeze

  validates :alert_type, inclusion: { in: ALERT_TYPES }
  validates :user_id, :observer_id, :alert_type, presence: true
  validates :alert_type, uniqueness: { scope: [:user_id, :observer_id] }
  validates :threshold, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :validate_threshold_type
  validate :validate_threshold_low_high
  validate :validate_users_link

  scope :active, -> { where.not(workflow_state: "deleted") }

  def validate_users_link
    unless users_are_still_linked?
      errors.add(:observer_id, "Observer must be linked to Student")
    end
  end

  def users_are_still_linked?
    return true if observer.as_observer_observation_links.active.where(student:).exists?
    return true if observer.enrollments.active.where(associated_user: student).shard(observer).exists?

    false
  end

  # Validates alert types that require a treshold
  # Also enforces _not_ passing a threshold if one is not required
  def validate_threshold_type
    # If a threshold is provided, there are only 4 applicable types of alert
    if threshold
      unless ALERT_TYPES_WITH_THRESHOLD.include? alert_type
        errors.add(:threshold, "Threshold is only applicable to the following alert types: #{ALERT_TYPES_WITH_THRESHOLD.join(", ")}")
      end
    else
      unless ALERT_TYPES_WITHOUT_THRESHOLD.include? alert_type
        errors.add(:threshold, "Threshold is required for the provided alert_type.")
      end
    end
  end

  # Validates the highs and lows of a single alert type, enforcing that a high threshold cannot be lower than a low threshold, or vica versa
  # For example:
  # If the user sets assignment_grade_high to be 40, and then tries to set assignment_grade_low to 50, that would be rejected.
  # On the flip side, if assignment_grade_low is set to 50, and then assignment_grade_high is set to 20, will be rejected
  def validate_threshold_low_high
    if ALERT_TYPES_WITH_THRESHOLD.include? alert_type
      opposite_type = if alert_type.include? "high"
                        alert_type.gsub("high", "low")
                      else
                        alert_type.gsub("low", "high")
                      end

      opposite = observer.as_observer_observer_alert_thresholds.where(alert_type: opposite_type)
      if opposite.any?
        if (alert_type.include? "high") && (threshold.to_i <= opposite.first.threshold.to_i)
          errors.add(:threshold, "You cannot set a high threshold that is lower or equal to a previously set low threshold.")
        elsif (alert_type.include? "low") && (threshold.to_i >= opposite.first.threshold.to_i)
          errors.add(:threshold, "You cannot set a low threshold that is higher or equal to a previously set high threshold.")
        end
      end
    end
  end

  def destroy
    self.workflow_state = "deleted"
    save!
  end

  def did_pass_threshold(previous_value, new_value)
    t = threshold.to_i
    if alert_type.include? "high"
      (previous_value.nil? || previous_value < t) && (!new_value.nil? && new_value > t)
    elsif alert_type.include? "low"
      (previous_value.nil? || previous_value > t) && (!new_value.nil? && new_value < t)
    end
  end
end

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
  belongs_to :student, :class_name => 'User', inverse_of: :as_student_observer_alert_thresholds, :foreign_key => :user_id
  belongs_to :observer, :class_name => 'User', inverse_of: :as_observer_observer_alert_thresholds
  has_many :observer_alerts, :inverse_of => :observer_alert_threshold

  ALERT_TYPES = %w(
    assignment_missing
    assignment_grade_high
    assignment_grade_low
    course_grade_high
    course_grade_low
    course_announcement
    institution_announcement
  ).freeze
  validates :alert_type, inclusion: { in: ALERT_TYPES }
  validates :user_id, :observer_id, :alert_type, presence: true
  validates :alert_type, uniqueness: { scope: [:user_id, :observer_id] }
  validate :validate_users_link

  scope :active, -> { where.not(workflow_state: 'deleted') }

  def validate_users_link
    unless users_are_still_linked?
      errors.add(:observer_id, "Observer must be linked to Student")
    end
  end

  # TODO: search cross-shard enrollments
  def users_are_still_linked?
    return true if observer.as_observer_observation_links.active.where(student: student).any?
    return true if observer.enrollments.active.where(associated_user: student).any?
    false
  end

  def destroy
    self.workflow_state = 'deleted'
    self.save!
  end

  def did_pass_threshold(previous_value, new_value)
    t = self.threshold.to_i
    if self.alert_type.include? 'high'
      return (previous_value.nil? || previous_value < t) && (!new_value.nil? && new_value > t)
    elsif self.alert_type.include? 'low'
      return (previous_value.nil? || previous_value > t) && (!new_value.nil? && new_value < t)
    end
  end
end

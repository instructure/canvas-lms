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

class ObserverAlert < ActiveRecord::Base
  belongs_to :student, :class_name => 'User', inverse_of: :as_student_observer_alerts, :foreign_key => :user_id
  belongs_to :observer, :class_name => 'User', inverse_of: :as_observer_observer_alerts
  belongs_to :observer_alert_threshold, :inverse_of => :observer_alerts
  belongs_to :context, polymorphic: [:discussion_topic, :assignment, :course, :account_notification, :submission]

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
  validates :user_id, :observer_id, :observer_alert_threshold_id, :alert_type, :action_date, :title, presence: true
  validate :validate_users_link

  scope :active, -> { where.not(workflow_state: ['dismissed', 'deleted']) }
  scope :unread, -> { where(workflow_state: 'unread') }

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

  def self.clean_up_old_alerts
    ObserverAlert.where('created_at < ?', 6.months.ago).delete_all
  end

  def self.create_assignment_missing_alerts
    submissions = Submission.active.
      eager_load(:assignment, user: :as_student_observer_alert_thresholds).
      where("observer_alert_thresholds.user_id = submissions.user_id").
      joins("LEFT OUTER JOIN #{ObserverAlert.quoted_table_name} ON observer_alerts.context_id = submissions.id
             AND observer_alerts.context_type = 'Submission'
             AND observer_alerts.alert_type = 'assignment_missing'").
      for_enrollments(Enrollment.all_active_or_pending).
      missing.
      merge(Assignment.submittable).
      where('cached_due_date > ?', 1.day.ago).
      where("observer_alerts.id IS NULL")

    alerts = []
    submissions.find_each do |submission|
      thresholds = submission.user.as_student_observer_alert_thresholds.
        where(alert_type: 'assignment_missing')
      thresholds.find_each do |threshold|
        next unless threshold.users_are_still_linked?
        next unless threshold.observer.enrollments.where(course_id: submission.assignment.context_id).first.present?

        now = Time.now.utc
        alerts << { observer_id: threshold.observer.id,
                    user_id: threshold.student.id,
                    observer_alert_threshold_id: threshold.id,
                    alert_type: "assignment_missing",
                    context_type: 'Submission',
                    context_id: submission.id,
                    created_at: now,
                    updated_at: now,
                    action_date: now,
                    title: I18n.t('Assignment missing: %{assignment_name} in %{course_code}', {
                      assignment_name: submission.assignment.title,
                      course_code: submission.assignment.course.course_code
                    }) }
      end
    end

    alerts.each_slice(1000) do |slice|
      ObserverAlert.bulk_insert(slice)
    end
  end
end

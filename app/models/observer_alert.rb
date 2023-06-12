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

class ObserverAlert < ActiveRecord::Base
  belongs_to :student, class_name: "User", inverse_of: :as_student_observer_alerts, foreign_key: :user_id
  belongs_to :observer, class_name: "User", inverse_of: :as_observer_observer_alerts
  belongs_to :observer_alert_threshold, inverse_of: :observer_alerts
  belongs_to :context, polymorphic: %i[discussion_topic assignment course account_notification submission]

  ALERT_TYPES = %w[
    assignment_missing
    assignment_grade_high
    assignment_grade_low
    course_grade_high
    course_grade_low
    course_announcement
    institution_announcement
  ].freeze
  validates :alert_type, inclusion: { in: ALERT_TYPES }
  validates :user_id, :observer_id, :observer_alert_threshold_id, :alert_type, :action_date, :title, presence: true
  validate :validate_users_link

  scope :active, -> { where.not(workflow_state: ["dismissed", "deleted"]) }
  scope :unread, -> { where(workflow_state: "unread") }

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

  def self.clean_up_old_alerts
    ObserverAlert.where("created_at < ?", 6.months.ago).in_batches(of: 10_000).delete_all
  end

  def self.create_assignment_missing_alerts
    alerts = []
    GuardRail.activate(:secondary) do
      last_user_id = nil
      now = Time.now.utc
      loop do
        scope = ObserverAlertThreshold
                .where(alert_type: "assignment_missing")
                .order(:user_id).limit(100)
        scope = scope.where("observer_alert_thresholds.user_id>?", last_user_id) if last_user_id
        user_ids = scope.distinct.pluck(:user_id)
        break if user_ids.empty?

        last_user_id = user_ids.last

        submissions = Submission
                      .select("submissions.id, submissions.assignment_id, assignments.title AS title, assignments.context_id AS course_id, observer_alert_thresholds.id AS observer_alert_threshold_id, observer_alert_thresholds.observer_id, observer_alert_thresholds.user_id, assignments.title")
                      .active
                      .joins(:assignment)
                      .joins("INNER JOIN #{ObserverAlertThreshold.quoted_table_name} ON observer_alert_thresholds.user_id=submissions.user_id")
                      .where(observer_alert_thresholds: { alert_type: "assignment_missing" })
                      .where(user_id: user_ids)
                      .for_enrollments(Enrollment.all_active_or_pending).
                      # users_are_still_linked?
                      where(ObserverEnrollment.where("enrollments.course_id=assignments.context_id AND enrollments.user_id=observer_alert_thresholds.observer_id AND enrollments.associated_user_id=submissions.user_id").arel.exists)
                      .missing
                      .merge(Assignment.submittable)
                      .merge(Assignment.published)
                      .where("late_policy_status = 'missing' OR cached_due_date > ?", 1.day.ago)
                      .where.not(ObserverAlert.where(context_type: "Submission", alert_type: "assignment_missing").where("context_id=submissions.id").arel.exists)

        submissions.find_in_batches do |batch|
          courses = Course.select(:id, :course_code).find(batch.map(&:course_id)).index_by(&:id)
          batch.each do |submission|
            alerts << { observer_id: submission.observer_id,
                        user_id: submission.user_id,
                        observer_alert_threshold_id: submission.observer_alert_threshold_id,
                        alert_type: "assignment_missing",
                        context_type: "Submission",
                        context_id: submission.id,
                        created_at: now,
                        updated_at: now,
                        action_date: now,
                        title: I18n.t("Assignment missing: %{assignment_name} in %{course_code}", {
                                        assignment_name: submission.title,
                                        course_code: courses[submission.course_id].course_code
                                      }) }
          end
        end
      end
    end

    alerts.each_slice(1000) do |slice|
      ObserverAlert.bulk_insert(slice)
    end
  end
end

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Alerts
  class DelayedAlertSender
    def self.process
      Account.root_accounts.active.find_each do |account|
        next unless account.settings[:enable_alerts]
        account.all_courses.active.find_ids_in_batches(batch_size: 200) do |batch|
          self.send_later_if_production_enqueue_args(:evaluate_courses,
                                                     {n_strand: ['delayed_alert_sender_evaluate_courses', account.global_id],
                                                      priority: Delayed::LOW_PRIORITY}, batch)
        end
      end
    end

    def self.evaluate_courses(course_ids)
      alerts_cache = {}
      Course.where(id: course_ids).find_each do |course|
        alerts_cache[course.account_id] ||= course.account.account_chain.map { |a| a.alerts.to_a }.flatten
        self.evaluate_for_course(course, alerts_cache[course.account_id])
      end
    end

    def self.evaluate_for_course(course, account_alerts)
      return unless course.available?

      alerts = Array.new(account_alerts || [])
      alerts.concat course.alerts.to_a
      return if alerts.empty?

      student_enrollments = course.student_enrollments
      student_ids = student_enrollments.map(&:user_id)
      return if student_ids.empty?

      teacher_enrollments = course.instructor_enrollments.active_or_pending
      teacher_ids = teacher_enrollments.map(&:user_id)
      return if teacher_ids.empty?

      teacher_student_mapper = Courses::TeacherStudentMapper.new(student_enrollments, teacher_enrollments)

      # Evaluate all the criteria for each user for each alert
      today = Time.now.beginning_of_day

      alert_checkers = {}

      alerts.each do |alert|
        student_ids.each do |user_id|
          matches = true

          alert.criteria.each do |criterion|
            alert_checker = alert_checkers[criterion.criterion_type] ||= Alerts.const_get(criterion.criterion_type, false).new(course, student_ids, teacher_ids)
            matches = !alert_checker.should_not_receive_message?(user_id, criterion.threshold.to_i)
            break unless matches
          end

          cache_key = [alert, user_id].cache_key
          if matches
            last_sent = Rails.cache.fetch(cache_key)
            if last_sent.blank?
            elsif alert.repetition.blank?
              matches = false
            else
              matches = last_sent + alert.repetition.days <= today
            end
          end
          if matches
            Rails.cache.write(cache_key, today)

            send_alert(alert, alert.resolve_recipients(user_id, teacher_student_mapper.teachers_for_student(user_id)), student_enrollments.to_ary.find { |enrollment| enrollment.user_id == user_id } )
          end
        end
      end
    end

    def self.send_alert(alert, user_ids, student_enrollment)
      notification = BroadcastPolicy.notification_finder.by_name("Alert")
      notification.create_message(alert, user_ids, {
        data: {
          student_name: student_enrollment.user.name,
          user_id: student_enrollment.user_id,
          course_id: student_enrollment.course_id
        }
      })
    end
  end
end

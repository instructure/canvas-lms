module Alerts
  class DelayedAlertSender
    def self.process
      Account.root_accounts.active.find_each do |account|
        next unless account.settings[:enable_alerts]
        self.send_later_if_production_enqueue_args(:evaluate_for_root_account, { :priority => Delayed::LOW_PRIORITY }, account)
      end
    end

    def self.evaluate_for_root_account(account)
      return unless account.settings[:enable_alerts]
      alerts_cache = {}
      account.associated_courses.where(:workflow_state => 'available').find_each do |course|
        alerts_cache[course.account_id] ||= course.account.account_chain.map { |a| a.alerts.all }.flatten
        self.evaluate_for_course(course, alerts_cache[course.account_id])
      end
    end

    def self.evaluate_for_course(course, account_alerts)
      return unless course.available?

      alerts = Array.new(account_alerts || [])
      alerts.concat course.alerts.all
      return if alerts.empty?

      student_enrollments = course.student_enrollments.active
      student_ids = student_enrollments.map(&:user_id)
      return if student_ids.empty?

      teacher_enrollments = course.instructor_enrollments.active
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
            alert_checker = alert_checkers[criterion.criterion_type] ||= Alerts.const_get(criterion.criterion_type).new(course, student_ids, teacher_ids)
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
      notification.create_message(alert, user_ids, {:asset_context => student_enrollment})
    end
  end
end

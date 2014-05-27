module Alerts
  class UngradedTimespan

    def initialize(course, student_ids, _ = nil)
      @ungraded_timespan_for_student = {}
      @today = Time.now.beginning_of_day
      ungraded_timespans = course.submissions.
        group("submissions.user_id").
        where(:user_id => student_ids).
        where(Submission.needs_grading_conditions).
        except(:order).
        minimum(:submitted_at)
      ungraded_timespans.each do |user_id, timespan|
        @ungraded_timespan_for_student[user_id] = timespan
      end
    end

    def should_not_receive_message?(user_id, threshold)
      (!@ungraded_timespan_for_student[user_id] || @ungraded_timespan_for_student[user_id] + threshold.days > @today)
    end

  end
end
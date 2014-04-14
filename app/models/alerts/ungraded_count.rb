module Alerts
  class UngradedCount

    def initialize(course, student_ids)
      @ungraded_count_for_student = {}
      ungraded_counts = course.submissions.
        group("submissions.user_id").
        where(:user_id => student_ids).
        where(Submission.needs_grading_conditions).
        except(:order).
        count
      ungraded_counts.each do |user_id, count|
        @ungraded_count_for_student[user_id] = count
      end
    end

    def should_not_receive_message?(user_id, threshold)
      (@ungraded_count_for_student[user_id].to_i < threshold)
    end

  end
end
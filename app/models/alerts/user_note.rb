module Alerts
  class UserNote

    def initialize(course, student_ids, teacher_ids)
      @user_notes_enabled = course.root_account.enable_user_notes?
      if @user_notes_enabled
        @last_note_for_user = {}
        @start_at = course.start_at || course.created_at
        @today = Time.now.beginning_of_day
        data = {}
        student_ids.each { |id| data[id] = {} }
        scope = ::UserNote.active.
            where(:created_by_id => teacher_ids, :user_id => student_ids)
        note_dates = scope.group(:user_id, :created_by_id).maximum(:created_at)
        note_dates.each do |key, date|
          student = data[key.first]
          (student[:last_user_note] ||= {})[key.last] = date
        end
        data.each do |student_id, user_data|
          user_data[:last_user_note] ||= {}
          @last_note_for_user[student_id] = user_data[:last_user_note].values.max
        end
      end
    end

    def should_not_receive_message?(user_id, threshold)
      return true unless @user_notes_enabled
      (@last_note_for_user[user_id] || @start_at) + threshold.days > @today
    end

  end
end
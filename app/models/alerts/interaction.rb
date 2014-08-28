module Alerts
  class Interaction
    def initialize(course, student_ids, teacher_ids)
      data = {}
      student_ids.each { |id| data[id] = {} }
      @today = Time.now.beginning_of_day
      @start_at = course.start_at || course.created_at
      @last_interaction_for_user = {}
      scope = SubmissionComment.for_context(course).
          where(:author_id => teacher_ids, :recipient_id => student_ids)
      last_comment_dates = scope.group(:recipient_id, :author_id).maximum(:created_at)
      last_comment_dates.each do |key, date|
        student = data[key.first]
        (student[:last_interaction] ||= {})[key.last] = date
      end
      scope = ConversationMessage.
          joins('INNER JOIN conversation_participants ON conversation_participants.conversation_id=conversation_messages.conversation_id').
          where(:conversation_messages => { :author_id => teacher_ids, :generated => false }, :conversation_participants => { :user_id => student_ids })
      last_message_dates = scope.group('conversation_participants.user_id', 'conversation_messages.author_id').maximum(:created_at)
      last_message_dates.each do |key, date|
        student = data[key.first.to_i]
        last_interaction = (student[:last_interaction] ||= {})
        last_interaction[key.last] = [last_interaction[key.last], date].compact.max
      end

      data.each do |student_id, user_data|
        user_data[:last_interaction] ||= {}
        @last_interaction_for_user[student_id] = user_data[:last_interaction].values.max
      end
    end

    def should_not_receive_message?(user_id, threshold)
      (@last_interaction_for_user[user_id] || @start_at) + threshold.days > @today
    end
  end
end
class Notifier
  def send_notification()
  end

  def send_notification(record, dispatch, messages, to_list, asset_context=nil, data=nil)
    messages = DelayedNotification.send_later_if_production_enqueue_args(
        :process,
        {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1},
        record,
        messages,
        (to_list || []).compact.map(&:asset_string),
        asset_context,
        data
    )

    messages ||= DelayedNotification.new(
          :asset => record,
          :notification => messages,
          :recipient_keys => (to_list || []).compact.map(&:asset_string),
          :asset_context => asset_context,
          :data => data
      )

    if Rails.env.test?
      record.messages_sent[dispatch] = messages.is_a?(DelayedNotification) ? messages.process : messages
    end

    messages
  end
end

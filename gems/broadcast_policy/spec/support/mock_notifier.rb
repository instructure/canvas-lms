class MockNotifier
  attr_reader :messages
  
  def initialize
    @messages = []
  end

  def send_notification(record, dispatch, notification, recipients, context = nil, data = nil)
    @messages << {
      record: record,
      dispatch: dispatch,
      notification: notification,
      recipients: recipients,
      context: context,
      data: data
    }
  end
end

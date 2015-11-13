require 'rake'

module NotificationsCommon

  def setup_comm_channel(user, path = 'test@example.com', path_type = 'email')
    @channel = user.communication_channels.create(path: path, path_type: path_type)
    @channel.confirm
  end

  def setup_notification(user, params = {})
    default_params = {
        name: 'Conversation Message',
        category: 'TestImmediately',
        frequency: 'immediately',
        sms: false,
    }
    params = default_params.merge(params)

    n = Notification.create!(name: params[:name], category: params[:category])

    # we don't send notifications to sms channels automatically so will need a policy set up for that if sms is chosen
    if params[:sms] == true
      NotificationPolicy.create!(
        notification: n,
        communication_channel: user.communication_channel,
        frequency: params[:frequency]
      )
    end
  end

  def load_all_notifications
    load File.expand_path("../../../../lib/tasks/db_load_data.rake", __FILE__)
    Rake::Task.define_task(:environment)
    Rake::Task["db:load_notifications"].invoke
  end
end


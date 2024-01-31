# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
#

# This file creates notification messages. I hope that was already known.
# Users have multiple communication_channels and notification preferences at
# different levels. This file accounts for these details.
#
# There are three main types of messages that are created here:
# immediate_message, delayed_messages, and dashboard_messages.
#
class NotificationMessageCreator
  include LocaleSelection

  PENDING_DUPLICATE_MESSAGE_WINDOW = 6.hours

  attr_accessor :notification, :asset, :to_user_channels, :message_data
  attr_reader :courses, :account

  # Options can include:
  #  :to_list - A list of Users, User IDs, and CommunicationChannels to send to
  #  :data - Options merged with Message options
  def initialize(notification, asset, options = {})
    @notification = notification
    @asset = asset
    @to_user_channels = user_channels(options[:to_list])
    @user_counts = recent_messages_for_users(@to_user_channels.keys)
    @message_data = options.delete(:data)
    course_ids = @message_data&.dig(:course_ids)
    course_ids ||= [@message_data&.dig(:course_id)]
    root_account_id = @message_data&.dig(:root_account_id)
    if course_ids.any? && root_account_id
      @account = Account.find_cached(root_account_id)
      @courses = course_ids.map { |id| Course.new(id:, root_account_id: @account&.id) }
    end
  end

  # Public: create (and dispatch, and queue delayed) a message
  # for this notification, associated with the given asset, sent to the given recipients
  #
  # asset - what the message applies to. An assignment, a discussion, etc.
  # to_list - a list of who to send the message to. the list can contain Users, User ids, or CommunicationChannels
  # options - a hash of extra options to merge with the options used to build the Message
  #
  # Returns a list of the messages dispatched immediately
  def create_message
    dashboard_messages = []
    immediate_messages = []
    delayed_messages = []

    @to_user_channels.each do |user, channels|
      # asset_applied_to is used for the asset (ie assignment, announcement)
      # to filter users out that do not apply to the notification like when a due
      # date is different for a specific user when using variable due dates.
      next unless (asset = asset_applied_to(user))

      user_locale = infer_locale(user:, context: user_asset_context(asset), ignore_browser_locale: true)
      I18n.with_locale(user_locale) do
        # the channels in this method are all the users active channels or the
        # channels that were provided in the to_list.
        #
        # If the notification has an immediate_policy, it will create an
        # immediate_message or a delayed_message via build_fallback_for.
        # otherwise it will create a delayed_message. Any message can create a
        # dashboard message in addition to itself.
        channels.each do |channel|
          channel.set_root_account_ids(persist_changes: true, log: true)
          next unless notifications_enabled_for_courses?(user)

          if immediate_policy?(user, channel)
            immediate_messages << build_immediate_message_for(user, channel)
            delayed_messages << build_fallback_for(user, channel)
          else
            delayed_messages << build_delayed_message_for(user, channel)
          end
        end

        dashboard_messages << build_dashboard_message_for(user)
      end
    end
    [delayed_messages, dashboard_messages, immediate_messages].each(&:compact!)
    delayed_messages.each(&:save!)
    dispatch_immediate_messages(immediate_messages) + dispatch_dashboard_messages(dashboard_messages)
  end

  private

  # Notifications are enabled for a user in a course by default, but can be
  # disabled for notifications. The broadcast_policy needs to pass both the
  # course_id and the root_account_id to the set_broadcast_policy block for us
  # to be able to look up if it should be disabled. root_account_id is used
  # right now to look up the feature flag, but it can also be used to set
  # root_account_id on the message, or look up policy overrides in the future.
  # A user can disable notifications for a course with a notification policy
  # override.
  def notifications_enabled_for_courses?(user)
    # if the message is not summarizable?, it is in a context that notifications
    # cannot be disabled, so return true before checking.
    return true unless @notification.summarizable?

    return NotificationPolicyOverride.enabled_for_all_contexts(user, courses) if courses&.any?

    true
  end

  # fallback message is a summary message for email only that we create when we
  # have sent too many immediate messages to a user in a day.
  # returns delayed_message or nil
  def build_fallback_for(user, channel)
    # delayed_messages are only sent to email channels.
    # some types of notifications are only for immediate.
    return unless @notification.summarizable? && channel.path_type == "email"
    # we only send fallback when we did not send an immediate message, ie.
    # when the channel is bouncing or there have been too_many_messages
    return unless channel.bouncing? || too_many_messages_for?(user)

    fallback_policy = nil
    NotificationPolicy.unique_constraint_retry do
      # notification_policies are already loaded, so use find instead of generating a query
      fallback_policy = channel.notification_policies.find { |np| np.frequency == "daily" && np.notification_id.nil? }
      fallback_policy ||= channel.notification_policies.create!(frequency: "daily")
    end

    InstStatsd::Statsd.increment("message.fall_back_used", short_stat: "message.fall_back_used")
    build_summary_for(user, fallback_policy)
  end

  # returns delayed_message or nil
  def build_delayed_message_for(user, channel)
    # delayed_messages are only sent to email channels.
    # some types of notifications are only for immediate.
    return unless @notification.summarizable? && channel.path_type == "email"

    policy = effective_policy_for(user, channel)
    # if the policy is not daily or weekly, it is either immediate which was
    # picked up before in build_immediate_message_for, or it's never.
    return unless %w[daily weekly].include?(policy&.frequency)

    build_summary_for(user, policy) if policy
  end

  def build_summary_for(user, policy)
    user.shard.activate do
      message = user.messages.build(message_options_for(user))
      message.parse!("summary", root_account: @account)
      delayed_message = policy.delayed_messages.build(notification: @notification,
                                                      frequency: policy.frequency,
                                                      # policy.communication_channel should
                                                      # already be loaded in memory as the
                                                      # inverse association of loading the
                                                      # policy from the channel. passing the
                                                      # object through here lets the delayed
                                                      # message use it without having to re-query.
                                                      communication_channel: policy.communication_channel,
                                                      root_account_id: message.context_root_account.try(:id),
                                                      name_of_topic: message.subject,
                                                      link: message.url,
                                                      summary: message.body)
      delayed_message.context = @asset
      delayed_message.save! if Rails.env.test?
      delayed_message
    end
  end

  def build_immediate_message_for(user, channel)
    # if we have already created a fallback message, we don't want to make an
    # immediate message.
    return if @notification.summarizable? && too_many_messages_for?(user) && ["email", "sms"].include?(channel.path_type)

    message_options = message_options_for(user)
    message = user.messages.build(message_options.merge(communication_channel: channel, to: channel.path))
    message&.parse!(root_account: @account)
    message.workflow_state = "bounced" if channel.bouncing?
    message
  end

  def dispatch_immediate_messages(messages)
    Message.transaction do
      # Cancel any that haven't been sent out for the same purpose
      cancel_pending_duplicate_messages if Rails.env.production? || ENV["RAILS_LOAD_CANCEL_PENDING_DUPLICATE_MESSAGES"]
      messages.each do |message|
        message.stage_without_dispatch!
        message.save!
      end
    end
    # we filter out bounced messages now that they have been saved.
    messages = messages.select(&:staged?)
    MessageDispatcher.batch_dispatch(messages)
    messages
  end

  # returns a message or nil
  def build_dashboard_message_for(user)
    # Dashboard messages are only built if the user has finished registration,
    # if a user has never logged in, let's not spam the dashboard for no reason.
    return unless @notification.dashboard? && @notification.show_in_feed? && !user.pre_registered?

    message = user.messages.build(message_options_for(user).merge(to: "dashboard"))
    message.parse!(root_account: @account)
    message
  end

  def dispatch_dashboard_messages(messages)
    messages.each do |message|
      message.infer_defaults
      message.create_stream_items
    end
    messages
  end

  def effective_policy_for(user, channel)
    # a user can override the notification preference for a course or a
    # root_account, the course_id needs to be provided in the notification from
    # broadcast_policy in message_data, the lowest level override is the one
    # that should be respected.
    policy = override_policy_for(channel, "Course")
    policy ||= override_policy_for(channel, "Account")
    if !policy && should_use_default_policy?(user, channel)
      begin
        policy = channel.notification_policies.create!(notification_id: @notification.id, frequency: @notification.default_frequency(user))
      rescue ActiveRecord::RecordNotUnique => e
        # there is a race condition here that can happen if multiple jobs are trying to create the same
        # flavor of policy for the same user at the same time.  If we fail to save this one,
        # we should just allow the process to continue because it will find the right policy in the
        # next step of this method.
        Canvas::Errors.capture_exception(:notifications, e, :info)
      end
    end
    policy ||= channel.notification_policies.find { |np| np.notification_id == @notification.id }
    policy
  end

  def should_use_default_policy?(user, channel)
    # only use new policies for default channel when there are no other policies for the notification and user.
    # If another policy exists then it means the notification preferences page has been visited and null values
    # show as never policies in the UI.
    default_email?(user, channel) && (user.notification_policies.find { |np| np.notification_id == @notification.id }).nil?
  end

  def default_email?(user, channel)
    user.email_channel == channel
  end

  def override_policy_for(channel, context_type)
    # NotificationPolicyOverrides are already loaded and this find block is on
    # an array and can only have one for a given context and channel.
    ops = channel.notification_policy_overrides.select { |np| np.notification_id == @notification.id && np.context_type == context_type }
    case context_type
    when "Course"
      ops.find { |np| courses.map(&:id).include?(np.context_id) } if courses&.any?
    when "Account"
      ops.find { |np| np.context_id == account.id } if account
    end
  end

  def user_channels(to_list)
    to_user_channels = Hash.new([])
    # if this method is given users we preload communication channels and they
    # are already loaded so we are using the select :active? to not do another
    # query to load them again.
    users_from_to_list(to_list).each do |user|
      to_user_channels[user] += user.communication_channels.select { |cc| add_channel?(user, cc) }
    end
    # if the method gets communication channels, the user is loaded, and this
    # allows all the methods in this file to behave the same as if it were users.
    communication_channels_from_to_list(to_list).each do |channel|
      to_user_channels[channel.user] += [channel]
    end
    to_user_channels.each_value(&:uniq!)
    to_user_channels
  end

  # only send emails to active channels or registration notifications to default users' channel
  def add_channel?(user, channel)
    return false if channel.path_type == CommunicationChannel::TYPE_SMS

    channel.active? || (@notification.registration? && default_email?(user, channel))
  end

  def users_from_to_list(to_list)
    to_list = [to_list] unless to_list.is_a? Enumerable

    to_users = []
    to_users += User.find(to_list.select { |to| to.is_a? Numeric }.uniq)
    to_users += to_list.select { |to| to.is_a? User }
    to_users.uniq!

    to_users
  end

  def communication_channels_from_to_list(to_list)
    to_list = [to_list] unless to_list.is_a? Enumerable
    to_list.select { |to| to.is_a? CommunicationChannel }.uniq
  end

  def asset_applied_to(user)
    if asset.respond_to?(:filter_asset_by_recipient)
      asset.filter_asset_by_recipient(@notification, user)
    else
      asset
    end
  end

  def message_options_for(user)
    user_asset = asset_applied_to(user)

    message_options = {
      subject: @notification.subject,
      notification: @notification,
      notification_name: @notification.name,
      user:,
      context: user_asset,
    }

    # can't just merge these because nil values need to be overwritten in a later merge
    message_options[:delay_for] = @notification.delay_for if @notification.delay_for
    message_options[:data] = @message_data if @message_data
    message_options
  end

  def user_asset_context(user_asset)
    if user_asset.is_a?(Context)
      user_asset
    elsif user_asset.respond_to?(:context)
      user_asset.context
    end
  end

  def immediate_policy?(user, channel)
    # we want to ignore unconfirmed channels unless the notification is
    # registration because that is how the user can confirm the channel
    return true if @notification.registration?
    # pre_registered users should only get registration emails.
    return false if user.pre_registered?
    return false if channel.unconfirmed?
    return true if @notification.migration?

    policy = effective_policy_for(user, channel)
    policy&.frequency == "immediately"
  end

  def cancel_pending_duplicate_messages
    first_start_time = start_time = PENDING_DUPLICATE_MESSAGE_WINDOW.ago
    final_end_time = Time.now.utc
    first_partition = Message.infer_partition_table_name("created_at" => first_start_time)

    @to_user_channels.each_key do |user|
      # a user's messages exist on the user's shard
      user.shard.activate do
        loop do
          end_time = start_time + 7.days
          end_time = final_end_time if end_time > final_end_time
          scope = Message
                  .in_partition("created_at" => start_time)
                  .where(notification_id: @notification)
                  .for(@asset)
                  .by_name(@notification.name)
                  .for_user(@to_user_channels.keys)
                  .cancellable
          start_partition = Message.infer_partition_table_name("created_at" => start_time)
          end_partition = Message.infer_partition_table_name("created_at" => end_time)
          if first_partition == start_partition &&
             start_partition == end_partition
            scope = scope.where(created_at: start_time..end_time)
            break_this_loop = true
          elsif start_time == first_start_time
            scope = scope.where("created_at>=?", start_time)
          elsif start_partition == end_partition
            scope = scope.where("created_at<=?", end_time)
            break_this_loop = true
            # else <no conditions; we're addressing the entire partition>
          end
          scope.update_all(workflow_state: "cancelled") if Message.connection.table_exists?(start_partition)

          break if break_this_loop

          start_time = end_time
        end
      end
    end
  end

  def too_many_messages_for?(user)
    if @user_counts[user.id] >= user.max_messages_per_day
      InstStatsd::Statsd.increment("message.too_many_messages_for_was_true", short_stat: "message.too_many_messages_for_was_true")
      true
    end
  end

  # Cache the count for number of messages sent to a user/user-with-category,
  # it can also be manually re-set to reflect new rows added... this cache
  # data can get out of sync if messages are cancelled for being repeats...
  # not sure if we care about that...
  def recent_messages_for_users(users)
    GuardRail.activate(:secondary) do
      Hash.new(0).merge(Message.more_recent_than(24.hours.ago).where(user_id: users, to_email: true).group(:user_id).count)
    end
  end
end

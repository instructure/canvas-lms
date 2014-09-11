#
# Copyright (C) 2011 Instructure, Inc.
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

class NotificationPolicy < ActiveRecord::Base

  include NotificationPreloader
  belongs_to :communication_channel
  has_many :delayed_messages

  attr_accessible :notification, :communication_channel, :frequency, :notification_id, :communication_channel_id

  validates_presence_of :communication_channel_id, :frequency
  validates_inclusion_of :frequency, in: [Notification::FREQ_IMMEDIATELY,
                                          Notification::FREQ_DAILY,
                                          Notification::FREQ_WEEKLY,
                                          Notification::FREQ_NEVER]

  # This is for choosing a policy for another context, so:
  # NotificationPolicy.for(notification) or
  # communication_channel.notification_policies.for(notification)
  scope :for, lambda { |context|
    case context
    when User
      joins(:communication_channel).
          where("communication_channels.user_id=? AND communication_channels.workflow_state<>'retired'", context)
    when Notification
      where(:notification_id => context)
    else
      scoped
    end
  }
  
  # TODO: the scope name should be self-explanatory... change this to
  # by_frequency or something This is for choosing a policy by frequency
  scope :by, lambda { |freq| where(:frequency => Array(freq).map(&:to_s)) }

  scope :in_state, lambda { |state| where(:workflow_state => state.to_s) }

  def self.spam_blocked_by(user)
    NotificationPolicy.where(:communication_channel_id => user.communication_channels.pluck(:id)).delete_all
    cc = user.communication_channel
    cc.confirm
    Notification.all.each do |notification|
      if notification.category == "Message"
        NotificationPolicy.create(:notification => notification, :communication_channel => cc, :frequency => 'immediately')
      else
        NotificationPolicy.create(:notification => notification, :communication_channel => cc, :frequency => 'never')
      end
    end
    true
  rescue => e
    puts e.to_s
    false
  end

  def self.setup_for(user, params)
    # Check for user preference settings first. Some communication related options are available on the page.
    # Handle those if given.
    user_prefs = params[:user]
    # If have user preference settings and this is a root account, check further to see if settings can be changed
    if user_prefs && params[:root_account]
      user_prefs.each_pair do |key, value|
        bool_val = (value == 'true')
        # save the preference as a symbol (convert from string)
        case key.to_sym
          when :send_scores_in_emails
            # Only set if a root account and the root account allows the setting.
            if params[:root_account].settings[:allow_sending_scores_in_emails] != false
              user.preferences[:send_scores_in_emails] = bool_val
            end
          when :no_submission_comments_inbox
            user.preferences[:no_submission_comments_inbox] = bool_val
        end
      end
      user.save!
    else
      # User preference change not being made. Make a notification policy change.

      # Using the category name, fetch all Notifications for the category. Will set the desired value on them.
      notifications = Notification.all.select { |n| (n.category && n.category.underscore.gsub(/\s/, '_')) == params[:category] }.map(&:id)
      frequency = params[:frequency]

      # Find any existing NotificationPolicies for the category and the channel. If frequency is 'never', delete the
      # entry. If other than that, create or update the entry.
      NotificationPolicy.transaction do
        notifications.each do |notification_id|
          scope = user.notification_policies.
              where(communication_channel_id: params[:channel_id], notification_id: notification_id)
          p = scope.first_or_initialize
          # Set the frequency and save
          p.frequency = frequency
          p.save!
        end
      end # transaction
    end #if..else
    nil
  end

  # Fetch the user's NotificationPolicies but whenever a category is not
  # represented, create a NotificationPolicy on the primary
  # CommunicationChannel with a default frequency set.
  # Returns the full list of policies for the user
  #
  # ===== Arguments
  # * <tt>user</tt> - The User instance to load the values for.
  # * <tt>full_category_list</tt> - An array of Notification models that
  # represent the unique list of categories that should be displayed for the
  # user.
  #
  # ===== Returns
  # A list of NotificationPolicy entries for the user. May include newly
  # created entries if defaults were needed.
  def self.setup_with_default_policies(user, full_category_list)
    if user.communication_channel
      user.communication_channel.user = user
      find_all_for(user.communication_channel)
    end
    # Load and return user's policies after defaults may or may not have been set.
    # TODO: Don't load policies for retired channels
    NotificationPolicy.includes(:notification).for(user)
  end

  # Finds the current policy for a given communication channel, or creates it (with default)
  # and/or updates it
  def self.find_or_update_for(communication_channel, notification_name, frequency = nil)
    notification_name = notification_name.titleize
    notification = Notification.by_name(notification_name)
    raise ActiveRecord::RecordNotFound unless notification
    communication_channel.shard.activate do
      unique_constraint_retry do
        np = communication_channel.notification_policies.where(notification_id: notification).first
        if !np
          np = communication_channel.notification_policies.build(notification: notification)
          frequency ||= begin
            if communication_channel == communication_channel.user.communication_channel
              notification.default_frequency(communication_channel.user)
            else
              'never'
            end
          end
        end
        if frequency
          np.frequency = frequency
          np.save!
        end
        np
      end
    end
  end

  def self.find_all_for(communication_channel)
    communication_channel.shard.activate do
      policies = communication_channel.notification_policies.all
      Notification.all.each do |notification|
        next if policies.find { |p| p.notification_id == notification.id }
        NotificationPolicy.transaction(requires_new: true) do
          np = nil
          begin
            np = communication_channel.notification_policies.build(notification: notification)
            np.frequency = if communication_channel == communication_channel.user.communication_channel
                             notification.default_frequency(communication_channel.user)
                           else
                             'never'
                           end
            np.save!
          rescue ActiveRecord::RecordNotUnique
            np = nil
            raise ActiveRecord::Rollback
          end
          np ||= communication_channel.notification_policies.where(notification_id: notification).first
          policies << np
        end
      end
      policies
    end
  end
end

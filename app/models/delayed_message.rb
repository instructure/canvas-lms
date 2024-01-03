# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class DelayedMessage < ActiveRecord::Base
  include NotificationPreloader
  belongs_to :notification_policy, inverse_of: :delayed_messages
  belongs_to :notification_policy_override, inverse_of: :delayed_messages
  belongs_to :context, polymorphic:
    [
      :discussion_entry,
      :assignment,
      :submission_comment,
      :submission,
      :conversation_message,
      :course,
      :discussion_topic,
      :enrollment,
      :attachment,
      :assignment_override,
      :group_membership,
      :calendar_event,
      :wiki_page,
      :assessment_request,
      :account_user,
      :web_conference,
      :account,
      :user,
      :appointment_group,
      :collaborator,
      :account_report,
      :alert,
      :content_migration,
      :account_notification,
      {
        context_communication_channel: "CommunicationChannel",
        quiz_submission: "Quizzes::QuizSubmission",
        quiz_regrade_run: "Quizzes::QuizRegradeRun",
        master_migration: "MasterCourses::MasterMigration",
        quizzes: "Quizzes::Quiz"
      }
    ]
  belongs_to :communication_channel

  validates :summary, length: { maximum: maximum_text_length, allow_blank: true }
  validates :link, length: { maximum: maximum_text_length, allow_blank: true }
  validates :communication_channel_id, :workflow_state, presence: true

  before_save :set_send_at

  def summary=(val)
    if !val || val.length < self.class.maximum_text_length
      write_attribute(:summary, val)
    else
      write_attribute(:summary, val[0, self.class.maximum_text_length])
    end
  end

  scope :for, lambda { |context|
    case context
    when :daily
      where(frequency: "daily")
    when :weekly
      where(frequency: "weekly")
    when Notification
      where(notification_id: context)
    when NotificationPolicy
      where(notification_policy_id: context)
    when CommunicationChannel
      where(communication_channel_id: context)
    else
      where(context:)
    end
  }

  scope :in_state, ->(state) { where(workflow_state: state.to_s) }

  include Workflow

  workflow do
    state :pending do
      event :begin_send, transitions_to: :sent do
        self.batched_at = Time.now
      end
      event :cancel, transitions_to: :cancelled
    end

    state :cancelled
    state :sent
  end

  # This sets up a message and parses it internally.  Any template can
  # have these variables to build a message.  The most important one will
  # probably be delayed_messages, from which the right links and summaries
  # should be deliverable. After this is run on a list of delayed messages,
  # the regular dispatch process will take place.
  def self.summarize(delayed_message_ids)
    delayed_messages = DelayedMessage.where(id: delayed_message_ids.uniq)
    uniqs = {}
    # only include the most recent instance of each notification-context pairing
    delayed_messages.each do |m|
      uniqs[[m.context_id, m.context_type, m.notification_id]] = m
    end
    delayed_messages = uniqs.values
    delayed_messages = delayed_messages.sort_by { |dm| [dm.notification.sort_order, dm.notification.category] }
    first = delayed_messages.detect do |m|
      m.communication_channel&.active? &&
        !m.communication_channel.bouncing?
    end
    to = first.communication_channel rescue nil
    return nil unless to
    return nil if delayed_messages.empty?

    user = to.user rescue nil
    context = delayed_messages.select(&:context).compact.first.try(:context)
    return nil unless context # the context for this message has already been deleted

    notification = BroadcastPolicy.notification_finder.by_name("Summaries")
    path = HostUrl.outgoing_email_address
    root_account_id = delayed_messages.first.try(:root_account_id)
    locale = user.locale || (root_account_id && Account.where(id: root_account_id).first.try(:default_locale))
    I18n.with_locale(locale) do
      message = to.messages.build(
        subject: notification.subject,
        to: to.path,
        notification_name: notification.name,
        notification:,
        from: path,
        user:
      )
      message.delayed_messages = delayed_messages
      message.context = context
      message.root_account_id = root_account_id
      message.delay_for = 0
      message.parse!
      message.save
    end
  end

  protected

  MINUTES_PER_DAY = 60 * 24
  WEEKLY_ACCOUNT_BUCKETS = 4
  MINUTES_PER_WEEKLY_ACCOUNT_BUCKET = MINUTES_PER_DAY / WEEKLY_ACCOUNT_BUCKETS

  def set_send_at
    # no cc yet = wait
    return unless communication_channel&.user
    return if send_at

    # I got tired of trying to figure out time zones in my head, and I realized
    # if we do it this way, Rails will take care of it all for us!
    if frequency == "weekly"
      target = communication_channel.user.weekly_notification_time
    else
      # Find the appropriate timezone. For weekly notifications, always use
      # Eastern. For other notifications, try and user the user's time zone,
      # defaulting to mountain. (Should be impossible to not find mountain, but
      # default to system time if necessary.)
      time_zone = communication_channel.user.time_zone || ActiveSupport::TimeZone["America/Denver"] || Time.zone
      target = time_zone.now.change(hour: 18)
      target += 1.day if target < time_zone.now
    end

    # Set the send_at value
    self.send_at = target
  end
end

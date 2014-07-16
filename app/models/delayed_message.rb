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

class DelayedMessage < ActiveRecord::Base
  include PolymorphicTypeOverride
  override_polymorphic_types context_type: {'QuizSubmission' => 'Quizzes::QuizSubmission'}

  belongs_to :notification
  belongs_to :notification_policy
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['DiscussionEntry', 'Assignment',
    'SubmissionComment', 'Submission', 'ConversationMessage', 'Course', 'DiscussionTopic',
    'Enrollment', 'Attachment', 'AssignmentOverride', 'Quizzes::QuizSubmission', 'GroupMembership',
    'CalendarEvent', 'WikiPage', 'AssessmentRequest', 'AccountUser', 'WebConference', 'Account', 'User',
    'AppointmentGroup', 'Collaborator', 'AccountReport', 'Quizzes::QuizRegradeRun', 'CommunicationChannel']
  belongs_to :communication_channel
  attr_accessible :notification, :notification_policy, :frequency,
    :communication_channel, :linked_name, :name_of_topic, :link, :summary,
    :notification_id, :notification_policy_id, :context_id, :context_type,
    :communication_channel_id, :context, :workflow_state, :root_account_id

  validates_length_of :summary, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :communication_channel_id, :workflow_state

  before_save :set_send_at
  
  def summary=(val)
    if !val || val.length < self.class.maximum_text_length
      write_attribute(:summary, val)
    else
      write_attribute(:summary, val[0,self.class.maximum_text_length])
    end
  end

  def formatted_summary
    (summary || '').
        gsub(/\n/, "<br />\n").
        gsub(/(\s\s+)/) { |str| str.gsub(/\s/, '&nbsp;') }
  end

  scope :for, lambda { |context|
    case context
    when :daily
      where(:frequency => 'daily')
    when :weekly
      where(:frequency => 'weekly')
    when Notification
      where(:notification_id => context)
    when NotificationPolicy
      where(:notification_policy_id => context)
    when CommunicationChannel
      where(:communication_channel_id => context)
    else
      where(:context_id => context, :context_type => context.class.base_ar_class.to_s)
    end
  }
  
  scope :by, lambda { |field| order(field) }
  
  scope :in_state, lambda { |state| where(:workflow_state => state.to_s) }

  scope :to_summarize, lambda {
    where("delayed_messages.workflow_state='pending' and delayed_messages.send_at<=?", Time.now.utc)
  }
  
  scope :next_to_summarize, lambda {
    where(:workflow_state => 'pending').order(:send_at).limit(1)
  }
  
  include Workflow
  
  workflow do
    state :pending do
      event :begin_send, :transitions_to => :sent do
        self.batched_at = Time.now
      end
      event :cancel, :transitions_to => :cancelled
    end
    
    state :cancelled
    state :sent
  end
  
  def linked_name=(name)
  end
  
  # This sets up a message and parses it internally.  Any template can
  # have these variables to build a message.  The most important one will
  # probably be delayed_messages, from which the right links and summaries
  # should be deliverable. After this is run on a list of delayed messages,
  # the regular dispatch process will take place. 
  def self.summarize(delayed_message_ids)
    delayed_messages = DelayedMessage.includes(:notification).find_all_by_id(delayed_message_ids.uniq).compact
    uniqs = {}
    # only include the most recent instance of each notification-context pairing
    delayed_messages.each do |m|
      uniqs[[m.context_id, m.context_type, m.notification_id]] = m
    end
    delayed_messages = uniqs.map{|key, val| val}.compact
    delayed_messages = delayed_messages.sort_by{|dm| [dm.notification.sort_order, dm.notification.category] }
    first = delayed_messages.detect{|m| m.communication_channel}
    to = first.communication_channel rescue nil
    return nil unless to
    return nil if delayed_messages.empty?
    user = to.user rescue nil
    context = delayed_messages.select{|m| m.context}.compact.first.try(:context)
    return nil unless context # the context for this message has already been deleted
    notification = Notification.by_name('Summaries')
    path = HostUrl.outgoing_email_address
    message = to.messages.build(
      :subject => notification.subject,
      :to => to.path,
      :notification_name => notification.name,
      :notification => notification,
      :from => path,
      :user => user
    )
    message.delayed_messages = delayed_messages
    message.context = context
    message.asset_context = context.context(user) rescue context
    message.root_account_id = delayed_messages.first.try(:root_account_id)
    message.delay_for = 0
    message.parse!
    message.save
  end

  protected
    MINUTES_PER_DAY = 60 * 24
    WEEKLY_ACCOUNT_BUCKETS = 4
    MINUTES_PER_WEEKLY_ACCOUNT_BUCKET = MINUTES_PER_DAY / WEEKLY_ACCOUNT_BUCKETS

    def set_send_at
      # no cc yet = wait
      return unless self.communication_channel and self.communication_channel.user
      return if self.send_at

      # I got tired of trying to figure out time zones in my head, and I realized
      # if we do it this way, Rails will take care of it all for us!
      if self.frequency == 'weekly'
        target = self.communication_channel.user.weekly_notification_time
      else
        # Find the appropriate timezone. For weekly notifications, always use
        # Eastern. For other notifications, try and user the user's time zone,
        # defaulting to mountain. (Should be impossible to not find mountain, but
        # default to system time if necessary.)
        time_zone = self.communication_channel.user.time_zone || ActiveSupport::TimeZone['America/Denver'] || Time.zone
        target = time_zone.now.change(:hour => 18)
        target += 1.day if target < time_zone.now
      end

      # Set the send_at value
      self.send_at = target
    end

end

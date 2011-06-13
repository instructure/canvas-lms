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

class Notification < ActiveRecord::Base
  validates_length_of :body, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  include Workflow
  
  TYPES_TO_SHOW_IN_FEED = ["Assignment Due Date Changed", 
    "Assignment Publishing Reminder", 
    "Assignment Grading Reminder", 
    "Assignment Due Date Reminder", 
    "Assignment Created", 
    "Grade Weight Changed", 
    "Assignment Graded", 
    "New Event Created", 
    "Event Date Changed", 
    "Collaboration Invitation", 
    "Web Conference Invitation", 
    "Enrollment Invitation", 
    "Enrollment Registration", 
    "Enrollment Notification", 
    "Enrollment Accepted", 
    "New Context Group Membership", 
    "New Context Group Membership Invitation", 
    "Group Membership Accepted", 
    "Group Membership Rejected", 
    "New Student Organized Group", 
    "Rubric Assessment Submission Reminder", 
    "Rubric Assessment Invitation", 
    "Rubric Association Created", 
    "Assignment Submitted Late", 
    "Group Assignment Submitted Late",
    "Show In Feed",
    "Migration Import Finished",
    "Migration Import Failed",
  ].freeze
  
  has_many :messages
  has_many :notification_policies, :dependent => :destroy
  has_many :users, :through => :notification_policies
  before_save :infer_default_content

  attr_accessible  :name, :subject, :body, :sms_body, :main_link, :delay_for, :category
  
  named_scope :to_show_in_feed, :conditions => ["messages.category = ? OR messages.notification_name IN (?) ", "TestImmediately", TYPES_TO_SHOW_IN_FEED]
  
  workflow do
    state :active do
      event :deactivate, :transitions_to => :inactive
    end
    
    state :inactive do
      event :reactivate, :transitions_to => :active
    end

  end
  
  def self.summary_notification
    find_by_name('Summaries')
  end

  def infer_default_content
    self.body ||= "No comments"
    self.subject ||= "No Subject"
    self.sms_body ||= "No comments"
  end
  protected :infer_default_content
  
  # If there is a policy for summarizing this message, a DelayedMessage is
  # created with the credentials for the summary service to send out the
  # right messages. 
  def record_delayed_messages(opts={})
    @delayed_messages_to_save ||= []
    user = opts[:user]
    cc = opts[:communication_channel]
    raise ArgumentError, "Must provide a user" unless user

    asset = opts[:asset] || raise(ArgumentError, "Must provide an asset")

    policies = user.notification_policies.select{|p| p.notification_id == self.id && p.communication_channel_id}
    policies << NotificationPolicy.create(:notification => self, :user => user, :communication_channel => cc, :frequency => self.default_frequency) if policies.empty? && cc && cc.active?
    policies = policies.select{|p| [:daily,:weekly].include?(p.frequency.to_sym) } #NotificationPolicy.for(self).for(user).by([:daily, :weekly])
    
    # If we pass in a fallback_channel, that means this message has been
    # throttled, so it definitely needs to go to at least one communication
    # channel with 'daily' as the frequency.
    if !policies.any?{|p| p.frequency == 'daily'} && opts[:fallback_channel]
      policies << NotificationPolicy.new(:user => user, :communication_channel => opts[:fallback_channel], :frequency => 'daily')
    end

    return false if (!opts[:fallback_channel] && cc && !cc.active?) || policies.empty? || self.registration?

    policies.inject([]) do |list, policy|
      message = Message.new(
        :subject => self.subject
      )
      message.body = self.sms_body
      message.notification = self
      message.notification_name = self.name
      message.user = user
      message.context = asset
      message.asset_context = asset.context(user) rescue asset
      message.parse!('summary')
      delayed_message = DelayedMessage.new(
        :notification => self,
        :notification_policy => policy,
        :frequency => policy.frequency,
        :communication_channel_id => policy.communication_channel_id,
        :linked_name => 'work on this link!!!',
        :name_of_topic => message.subject,
        :link => message.url,
        :summary => message.body
      )
      delayed_message.context = asset
      @delayed_messages_to_save << delayed_message
      delayed_message.save! if ENV['RAILS_ENV'] == 'test'
      list << delayed_message
    end
  end
  
  def create_message(asset, *tos)
    tos = tos.flatten.compact.uniq
    mailbox = asset.messaging_mailbox
    @delayed_messages_to_save = []
    recipient_ids = []
    recipients = []
    tos.each do |to|
      if to.is_a?(CommunicationChannel)
        recipients << to
      else
        user = nil
        case to
        when User
          user = to
        when Numeric
          user = User.find(to)
        when CommunicationChannel
          user = to.user
        end
        recipient_ids << user.id if user
      end
    end
    
    recipients += User.find(:all, :conditions => {:id => recipient_ids}, :include => [:communication_channels, :notification_policies])
    
    # Cancel any that haven't been sent out for the same purpose
    all_matching_messages = self.messages.for(asset).by_name(name).for_user(recipients).in_state([:created,:staged,:sending,:dashboard])
    Message.update_all("workflow_state='cancelled'", "id IN (#{all_matching_messages.map(&:id).join(',')})") unless all_matching_messages.empty?
    
    messages = []
    @user_counts = {}
    recipients.uniq.each do |recipient|
      cc = nil
      user = nil
      if recipient.is_a?(CommunicationChannel)
        cc = recipient
        user = cc.user
      elsif recipient.is_a?(User)
        user = recipient
        cc = user.communication_channels.first
      end
      
      # For non-essential messages, check if too many have gone out, and if so
      # send this message as a daily summary message instead of immediate.
      too_many_and_summarizable = user && self.summarizable? && too_many_messages?(user)
      channels = CommunicationChannel.find_all_for(user, self, cc)
      fallback_channel = channels.sort_by{|c| c.path_type }.first
      record_delayed_messages(:user => user, :communication_channel => cc, :asset => asset, :fallback_channel => too_many_and_summarizable ? channels.first : nil)
      if too_many_and_summarizable
        channels = channels.select{|cc| cc.path_type != 'email' && cc.path_type != 'sms' }
      end
      channels << "dashboard" if self.dashboard? && self.show_in_feed?
      channels.clear if !user || (user.pre_registered? && !self.registration?)
      channels.each do |c|
        to_path = c
        to_path = c.path if c.respond_to?("path")

        message = self.messages.build(
          :subject => self.subject, 
          :to => to_path
        )
        
        message.body = self.body
        message.body = self.sms_body if c.respond_to?("path_type") && c.path_type == "sms"
        message.notification_name = self.name
        message.from = mailbox ? mailbox.path : nil
        message.communication_channel = c if c.is_a?(CommunicationChannel)
        message.dispatch_at = nil
        message.user = user
        message.context = asset
        message.asset_context = asset.context(user) rescue asset
        message.notification_category = self.category
        message.delay_for = self.delay_for if self.delay_for 
        message.parse!
        # keep track of new messages added for caching so we don't
        # have to re-look it up
        @user_counts[user.id] ||= 0
        @user_counts[user.id] += 1 if c.respond_to?(:path_type) && ['email', 'sms'].include?(c.path_type)
        @user_counts["#{user.id}_#{self.category_spaceless}"] ||= 0
        @user_counts["#{user.id}_#{self.category_spaceless}"] += 1 if c.respond_to?(:path_type) && ['email', 'sms'].include?(c.path_type)
        messages << message
      end
    end
    @delayed_messages_to_save.each{|m| m.save! }

    dashboard_messages, dispatch_messages = messages.partition { |m| m.to == 'dashboard' }

    dashboard_messages.each do |m|
      if Notification.types_to_show_in_feed.include?(self.name)
        m.set_asset_context_code
        m.infer_defaults
        m.create_stream_items
      end
    end

    dispatch_messages.each { |m| m.stage_without_dispatch!; m.save! }
    MessageDispatcher.batch_dispatch(dispatch_messages)

    # re-set cached values
    @user_counts.each{|user_id, cnt| recent_messages_for_user(user_id, cnt) }

    messages
  end
  
  def category_spaceless
    (self.category || "None").gsub(/\s/, "_")
  end
  
  def too_many_messages?(user)
    return false unless user
    all_messages = recent_messages_for_user(user.id) || 0
    @user_counts[user.id] = all_messages
    for_category = recent_messages_for_user("#{user.id}_#{self.category_spaceless}") || 0
    @user_counts["#{user.id}_#{self.category_spaceless}"] = for_category
    all_messages >= user.max_messages_per_day || (max_for_category && for_category >= max_for_category)
  end
  
  # Cache the count for number of messages sent to a user/user-with-category,
  # it can also be manually re-set to reflect new rows added... this cache
  # data can get out of sync if messages are cancelled for being repeats...
  # not sure if we care about that...
  def recent_messages_for_user(id, messages=nil)
    if !id
      nil
    elsif messages
      Rails.cache.write(['recent_messages_for', id].cache_key, messages, :expires_in => 1.hour)
    else
      category = nil
      user_id = id
      if id.is_a?(String)
        user_id, category = id.split(/_/)
      end
      messages = Rails.cache.fetch(['recent_messages_for', id].cache_key, :expires_in => 1.hour) do
        lookup = Message.scoped(:conditions => ['dispatch_at > ? AND user_id = ? AND to_email = ?', 24.hours.ago, user_id, true])
        if category
          lookup = lookup.scoped(:conditions => ['notification_category = ?', category.gsub(/_/, " ")])
        end
        lookup.count
      end
    end
  end
  
  # Maximum number of messages a user can receive per day per category
  # These numbers are totally pulled out of the air
  def max_for_category
    case category
    when 'Calendar'
      5
    when 'Course Content'
      5
    when 'Files'
      5
    when 'Discussion'
      5
    when 'DiscussionEntry'
      5
    when 'Due Date'
      10
    when 'Grading Policies'
      3
    when 'Membership Update'
      5
    when 'Student Message'
      5
    else
      nil
    end
  end
  
  def sort_order
    case category
    when 'Message'
      0
    when 'Announcement'
      1
    when 'Student Message'
      2
    when 'Grading'
      3
    when 'Late Grading'
      4
    when 'Registration'
      5
    when 'Invitation'
      6
    when 'Grading Policies'
      7
    when 'Submission Comment'
      8
    else
      9
    end
  end
  
  def self.types_to_show_in_feed
     TYPES_TO_SHOW_IN_FEED
  end
  
  def show_in_feed?
   self.category == "TestImmediately" || Notification.types_to_show_in_feed.include?(self.name)
  end
  
  def show_in_feed?
    self.category == "TestImmediately" || Notification.types_to_show_in_feed.include?(self.name)
  end
  
  def registration?
    return self.category == "Registration"
  end
  
  def summarizable?
    return !self.registration? && self.category != 'Message'
  end
  
  def dashboard?
    return self.category != "Registration" && self.category != "Summaries"
  end
  
  def category_slug
    (self.category || "").gsub(/ /, "_").gsub(/[^\w]/, "").downcase
  end
  
  # if user is given, categories that aren't relevant to that user will be
  # filtered out.
  def self.dashboard_categories(user = nil)
    seen_types = {}
    res = []
    Notification.find(:all).each do |n|
      if !seen_types[n.category] && (user.nil? || n.relevant_to_user?(user))
        seen_types[n.category] = true
        res << n if n.category && n.category != "Registration" && n.category != 'Summaries'
      end
    end
    res.sort_by{|n| n.category == "Other" ? "zzzz" : n.category }
  end
  
  def default_frequency
    case category
    when 'All Submissions'
      'never'
    when 'Announcement'
      'immediately'
    when 'Calendar'
      'never'
    when 'Course Content'
      'never'
    when 'Files'
      'never'
    when 'Discussion'
      'never'
    when 'DiscussionEntry'
      'daily'
    when 'Due Date'
      'weekly'
    when 'Grading'
      'immediately'
    when 'Grading Policies'
      'weekly'
    when 'Invitation'
      'immediately'
    when 'Late Grading'
      'daily'
    when 'Membership Update'
      'daily'
    when 'Student Message'
      'daily'
    when 'Message'
      'immediately'
    when 'Other'
      'daily'
    when 'Registration'
      'immediately'
    when 'Submission Comment'
      'daily'
    when 'Reminder'
      'daily'
    when 'TestImmediately'
      'immediately'
    when 'TestDaily'
      'daily'
    when 'TestWeekly'
      'weekly'
    when 'TestNever'
      'never'
    else
      'daily'
    end
  end
  
  def category_description
    case category
    when 'Announcement'
      "For new announcements"
    when 'Course Content'
      "For changes to course pages"
    when 'Files'
      "For new files"
    when 'Discussion'
      "For new topics"
    when 'DiscussionEntry'
      "For topics I've commented on"
    when 'Due Date'
      "For due date changes"
    when 'Grading'
      "For course grading alerts"
    when 'Late Grading'
      "For assignments turned in late"
    when 'All Submissions'
      "For all assignment submissions in courses you teach"
    when 'Submission Comment'
      "For comments on assignment submissions"
    when 'Grading Policies'
      "For course grading policy changes"
    when 'Invitation'
      "For new invitations"
    when 'Other'
      "For any other alerts"
    when 'Calendar'
      "For calendar changes"
    when 'Message'
      "For new email messages"
    when 'Student Message'
      "For private messages from students"
    else
      'For ' + (category || "Notification") + ' alerts'
    end
  end
  
  def type_name
    return category
  end

  def relevant_to_user?(user)
    case category
    when 'All Submissions', 'Late Grading'
      user.teacher_enrollments.count > 0 || user.ta_enrollments.count > 0
    else
      true
    end
  end

end

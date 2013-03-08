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
  include LocaleSelection

  include Workflow

  TYPES_TO_SHOW_IN_FEED = [
    # Assignment
    "Assignment Created",
    "Assignment Changed",
    "Assignment Due Date Changed",
    "Assignment Due Date Override Changed",

    # Submissions / Grading
    "Assignment Graded",
    "Assignment Submitted Late",
    "Grade Weight Changed",
    "Group Assignment Submitted Late",

    # Testing
    "Show In Feed",
  ].freeze

  FREQ_IMMEDIATELY = 'immediately'
  FREQ_DAILY = 'daily'
  FREQ_WEEKLY = 'weekly'
  FREQ_NEVER = 'never'

  has_many :messages
  has_many :notification_policies, :dependent => :destroy
  before_save :infer_default_content

  attr_accessible  :name, :subject, :main_link, :delay_for, :category
  
  named_scope :to_show_in_feed, :conditions => ["messages.category = ? OR messages.notification_name IN (?) ", "TestImmediately", TYPES_TO_SHOW_IN_FEED]

  validates_uniqueness_of :name

  workflow do
    state :active do
      event :deactivate, :transitions_to => :inactive
    end
    
    state :inactive do
      event :reactivate, :transitions_to => :active
    end

  end

  def self.summary_notification
    by_name('Summaries')
  end

  def self.by_name(name)
    @notifications ||= Notification.all.inject({}){ |h, n| h[n.name] = n; h }
    if notification = @notifications[name]
      copy = notification.clone
      copy.id = notification.id
      copy.send(:remove_instance_variable, :@new_record)
      copy
    end
  end

  def self.reset_cache!
    @notifications = nil
  end

  def infer_default_content
    self.subject ||= t(:no_subject, "No Subject")
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

    policies = NotificationPolicy.for(user).for(self).to_a
    policies << NotificationPolicy.create(:notification => self, :communication_channel => cc, :frequency => self.default_frequency) if policies.empty? && cc && cc.active?
    policies = policies.select{|p| [:daily,:weekly].include?(p.frequency.to_sym) }

    # If we pass in a fallback_channel, that means this message has been
    # throttled, so it definitely needs to go to at least one communication
    # channel with 'daily' as the frequency.
    if !policies.any?{|p| p.frequency == 'daily'} && opts[:fallback_channel]
      fallback_policy = opts[:fallback_channel].notification_policies.by(:daily).find(:first, :conditions => { :notification_id => nil })
      fallback_policy ||= NotificationPolicy.new(:communication_channel => opts[:fallback_channel], :frequency => 'daily')
      policies << fallback_policy
    end

    return false if (!opts[:fallback_channel] && cc && !cc.active?) || policies.empty? || !self.summarizable?

    policies.inject([]) do |list, policy|
      message = Message.new(
        :subject => self.subject
      )
      message.notification = self
      message.notification_name = self.name
      message.user = user
      message.context = asset
      message.asset_context = opts[:asset_context] || asset.context(user) rescue asset
      message.data = opts[:data] if opts[:data]
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
      delayed_message.save! if Rails.env.test?
      list << delayed_message
    end
  end

  def users_from_to_list(to_list)
    to_list = [to_list] unless to_list.is_a? Enumerable

    to_user_ids = []
    to_user_ids += to_list.select{ |to| to.is_a? Numeric }
    to_user_ids += to_list.select{ |to| to.is_a? User }.collect{ |user| user.id }
    to_user_ids.uniq!
    
    User.find(:all, :conditions => {:id =>to_user_ids}, :include => { :communication_channels => :notification_policies})
  end
  
  def communication_channels_from_to_list(to_list)
    to_list = [to_list] unless to_list.is_a? Enumerable
    
    to_list.select{ |to| to.is_a? CommunicationChannel }.uniq
  end

  def asset_filtered_by_user(asset, user)
    if asset.respond_to?(:filter_asset_by_recipient)
      asset.filter_asset_by_recipient(self, user)
    else
      asset
    end
  end
  
  def message_options_for(asset, user)
    user_asset = asset_filtered_by_user(asset, user)
 
    asset_context = user_asset.context(user) rescue user_asset
   
    message_options = {
      :subject => subject,
      :notification => self,
      :notification_name => name,
      :user => user,
      :context => user_asset,
      :asset_context => asset_context,
    }
    message_options[:delay_for] = delay_for if delay_for
    message_options
  end

  def increment_user_counts(user_id, count)
    @user_counts[user_id] ||= 0
    @user_counts[user_id] += count
    @user_counts["#{user_id}_#{self.category_spaceless}"] ||= 0
    @user_counts["#{user_id}_#{self.category_spaceless}"] += count
  end
  
  def user_asset_context(user_asset)
    if user_asset.is_a?(Context)
      user_asset
    elsif user_asset.respond_to?(:context)
      user_asset.context
    end
  end

  # creates and saves a delayed message for each given communication channel 
  def create_delayed_message(asset, to_channels, data=nil, options={})
    @delayed_messages_to_save = []
    to_channels.each do |to_channel|
      user = to_channel.user
      
      I18n.locale = infer_locale(:user => user,
                                 :context => user_asset_context(asset_filtered_by_user(asset, user)))

      
      # For non-essential messages, check if too many have gone out, and if so
      # send this message as a daily summary message instead of immediate.
      fallback_channel = if should_throttle_for?(user)
                           CommunicationChannel.find_all_for(user, self, to_channel).sort_by(&:path_type).first
                         end

      delayed_options = options.merge(:user => user,
                                      :communication_channel => to_channel,
                                      :asset => asset_filtered_by_user(asset, user),
                                      :fallback_channel => fallback_channel)
      delayed_options[:data] = data if data
      
      record_delayed_messages(delayed_options)
    end
    @delayed_messages_to_save.each{ |message| message.save! }
  end

  # builds a message for each applicable communication channel (plus one for the dashboard) on each user
  def build_immediate_messages(asset, to_users, data=nil, asset_context=nil)
    messages = []
    to_users.each do |user|
      I18n.locale = infer_locale(:user => user,
                                 :context => user_asset_context(asset_filtered_by_user(asset, user)))

      message_options = message_options_for(asset, user)

      # can't just merge these because nil values need to be overwritten
      message_options[:data] = data if data
      message_options[:asset_context] = asset_context if asset_context

      channels = CommunicationChannel.find_all_for(user, self, user.email_channel)
      channels.reject!{ |channel| ['email', 'sms'].include?(channel.path_type) } if should_throttle_for?(user)

      messages += channels.map do |channel|
        user.messages.build(message_options.merge(:communication_channel => channel,
                                                  :to => channel.path))
      end

      messages << user.messages.build(message_options.merge(:to => 'dashboard')) if dashboard? && show_in_feed?

      increment_user_counts(user.id, channels.count{ |channel| ['email', 'sms'].include?(channel.path_type) })
    end
    messages.each{ |message| message.parse! }
  end
  
  def create_immediate_message(asset, to_users, data=nil, options={})
    messages = build_immediate_messages(asset, to_users, data, options[:asset_context])
    dashboard_messages, dispatch_messages = messages.partition { |message| message.to == 'dashboard' }

    dashboard_messages.each do |message|
      if Notification.types_to_show_in_feed.include?(name)
        message.set_asset_context_code
        message.infer_defaults
        message.create_stream_items
      end
    end

    Message.transaction do
      # Cancel any that haven't been sent out for the same purpose
      cancel_messages_for(asset, to_users)
      dispatch_messages.each do |message|
        message.stage_without_dispatch!
        message.save!
      end
    end
    MessageDispatcher.batch_dispatch(dispatch_messages)

    messages
  end
  
  # Public: create (and dispatch, and queue delayed) a message
  #  for this notication, associated with the given asset, sent to the given recipients
  #
  # asset - what the message applies to. An assignment, a discussion, etc.
  # to_list - a list of who to send the message to. the list can contain Users, User ids, or communication channels
  # options - a hash of extra options to merge with the options used to build the Message
  #
  # Returns a list of the messages dispatched immediately
  def create_message(asset, to_list, options={})
    # to_list can include Users, User IDs, CommunicationChannels, or nils.
    # to_list can contain duplicates
    # to_list might just be one thing rather than a list
    current_locale = I18n.locale

    @user_counts = {}
    data = options.delete(:data)
    
    users_to_immediately_send_message_to = users_from_to_list(to_list)
    
    channels_to_send_delayed_message_to = communication_channels_from_to_list(to_list)

    # The original behavior of this method had the potential to duplicate messages if a user and
    # their communication channel were both in the to_list. This may not be correct behavior, but
    # it was kept this way to maintain bug-parity during a refactor.
    users_to_immediately_send_message_to += channels_to_send_delayed_message_to.collect(&:user)
    channels_to_send_delayed_message_to += users_to_immediately_send_message_to.collect(&:email_channel).compact

    channels_to_send_delayed_message_to.uniq!
    channels_to_send_delayed_message_to.reject!{ |channel| !asset_filtered_by_user(asset, channel.user) }
    create_delayed_message(asset, channels_to_send_delayed_message_to, data, options)
    
    # This must come after delayed messages because @user_counts affects too_many_messages? and pre_registered users still get delayed messages 
    users_to_immediately_send_message_to.reject!{ |user| !asset_filtered_by_user(asset, user) || (user.pre_registered? && !registration?) }
    messages = create_immediate_message(asset, users_to_immediately_send_message_to, data, options)
    
    # re-set cached values
    @user_counts.each{|user_id, count| recent_messages_for_user(user_id, count) }

    messages
  ensure
    I18n.locale = current_locale
  end
  
  def cancel_messages_for(asset, recipients)
    # doesn't include dashboard messages. should it?
    messages.
      for(asset).
      by_name(name).
      for_user(recipients).
      cancellable.
      update_all(:workflow_state => 'cancelled')
  end
  
  def category_spaceless
    (self.category || "None").gsub(/\s/, "_")
  end

  def should_throttle_for?(user)
    summarizable? && too_many_messages?(user)
  end
  
  def too_many_messages?(user)
    return false unless user
    all_messages = recent_messages_for_user(user.id) || 0
    @user_counts[user.id] = all_messages
    for_category = recent_messages_for_user("#{user.id}_#{self.category_spaceless}") || 0
    @user_counts["#{user.id}_#{self.category_spaceless}"] = for_category
    all_messages >= user.max_messages_per_day
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

  def sort_order
    case category
    when 'Announcement'
      1
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
  
  def registration?
    return self.category == "Registration"
  end

  def migration?
    return self.category == "Migration"
  end
  
  def summarizable?
    return !self.registration? && !self.migration?
  end
  
  def dashboard?
    return ["Migration", "Registration", "Summaries"].include?(self.category) == false
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
        res << n if n.category && n.dashboard?
      end
    end
    res.sort_by{|n| n.category == "Other" ? "zzzz" : n.category }
  end

  # Return a hash with information for a related user option if one exists.
  def related_user_setting(user)
    case self.category
      when 'Submission Comment'
        setting = {:name => :no_submission_comments_inbox, :value => user.preferences[:no_submission_comments_inbox],
                   :label => t(:submission_new_as_read, 'Mark new submission comments as read.')}
      when 'Grading'
        setting = {:name => :send_scores_in_emails, :value => user.preferences[:send_scores_in_emails],
                   :label => t(:grading_notify_include_grade, 'Include scores when alerting about grade changes.')}
      else
        nil
    end
    setting[:id] = "cat_#{self.id}_option" if setting
    setting
  end
  
  def default_frequency(user = nil)
    # user arg is used in plugins
    case category
    when 'All Submissions'
      FREQ_NEVER
    when 'Announcement'
      FREQ_IMMEDIATELY
    when 'Calendar'
      FREQ_NEVER
    when 'Student Appointment Signups'
      FREQ_NEVER
    when 'Appointment Availability'
      FREQ_IMMEDIATELY
    when 'Appointment Signups'
      FREQ_IMMEDIATELY
    when 'Appointment Cancelations'
      FREQ_IMMEDIATELY
    when 'Course Content'
      FREQ_NEVER
    when 'Files'
      FREQ_NEVER
    when 'Discussion'
      FREQ_NEVER
    when 'DiscussionEntry'
      FREQ_DAILY
    when 'Due Date'
      FREQ_WEEKLY
    when 'Grading'
      FREQ_IMMEDIATELY
    when 'Grading Policies'
      FREQ_WEEKLY
    when 'Invitation'
      FREQ_IMMEDIATELY
    when 'Late Grading'
      FREQ_DAILY
    when 'Membership Update'
      FREQ_DAILY
    when 'Other'
      FREQ_DAILY
    when 'Registration'
      FREQ_IMMEDIATELY
    when 'Migration'
      FREQ_IMMEDIATELY
    when 'Submission Comment'
      FREQ_DAILY
    when 'Reminder'
      FREQ_DAILY
    when 'TestImmediately'
      FREQ_IMMEDIATELY
    when 'TestDaily'
      FREQ_DAILY
    when 'TestWeekly'
      FREQ_WEEKLY
    when 'TestNever'
      FREQ_NEVER
    when 'Conversation Message'
      FREQ_IMMEDIATELY
    when 'Added To Conversation'
      FREQ_IMMEDIATELY
    else
      FREQ_DAILY
    end
  end
  
  # TODO i18n: show the localized notification name in the dashboard (or
  # wherever), even if we continue to store the english string in the db
  # (it's actually just the titleized message template filename)
  def names
    t 'names.account_user_notification', 'Account User Notification'
    t 'names.account_user_registration', 'Account User Registration'
    t 'names.assignment_changed', 'Assignment Changed'
    t 'names.assignment_created', 'Assignment Created'
    t 'names.assignment_due_date_changed', 'Assignment Due Date Changed'
    t 'names.assignment_due_date_override_changed', 'Assignment Due Date Override Changed'
    t 'names.assignment_graded', 'Assignment Graded'
    t 'names.assignment_resubmitted', 'Assignment Resubmitted'
    t 'names.assignment_submitted', 'Assignment Submitted'
    t 'names.assignment_submitted_late', 'Assignment Submitted Late'
    t 'names.collaboration_invitation', 'Collaboration Invitation'
    t 'names.confirm_email_communication_channel', 'Confirm Email Communication Channel'
    t 'names.confirm_registration', 'Confirm Registration'
    t 'names.confirm_sms_communication_channel', 'Confirm Sms Communication Channel'
    t 'names.content_export_failed', 'Content Export Failed'
    t 'names.content_export_finished', 'Content Export Finished'
    t 'names.enrollment_accepted', 'Enrollment Accepted'
    t 'names.enrollment_invitation', 'Enrollment Invitation'
    t 'names.enrollment_notification', 'Enrollment Notification'
    t 'names.enrollment_registration', 'Enrollment Registration'
    t 'names.event_date_changed', 'Event Date Changed'
    t 'names.forgot_password', 'Forgot Password'
    t 'names.grade_weight_changed', 'Grade Weight Changed'
    t 'names.group_assignment_submitted_late', 'Group Assignment Submitted Late'
    t 'names.group_membership_accepted', 'Group Membership Accepted'
    t 'names.group_membership_rejected', 'Group Membership Rejected'
    t 'names.merge_email_communication_channel', 'Merge Email Communication Channel'
    t 'names.migration_export_ready', 'Migration Export Ready'
    t 'names.migration_import_failed', 'Migration Import Failed'
    t 'names.migration_import_finished', 'Migration Import Finished'
    t 'names.new_account_user', 'New Account User'
    t 'names.new_announcement', 'New Announcement'
    t 'names.new_context_group_membership', 'New Context Group Membership'
    t 'names.new_context_group_membership_invitation', 'New Context Group Membership Invitation'
    t 'names.new_course', 'New Course'
    t 'names.new_discussion_entry', 'New Discussion Entry'
    t 'names.new_discussion_topic', 'New Discussion Topic'
    t 'names.new_event_created', 'New Event Created'
    t 'names.new_file_added', 'New File Added'
    t 'names.new_files_added', 'New Files Added'
    t 'names.new_student_organized_group', 'New Student Organized Group'
    t 'names.new_teacher_registration', 'New Teacher Registration'
    t 'names.new_user', 'New User'
    t 'names.pseudonym_registration', 'Pseudonym Registration'
    t 'names.report_generated', 'Report Generated'
    t 'names.report_generation_failed', 'Report Generation Failed'
    t 'names.rubric_assessment_invitation', 'Rubric Assessment Invitation'
    t 'names.rubric_assessment_submission_reminder', 'Rubric Assessment Submission Reminder'
    t 'names.rubric_association_created', 'Rubric Association Created'
    t 'names.conversation_message', 'Conversation Message'
    t 'names.added_to_conversation', 'Added To Conversation'
    t 'names.submission_comment', 'Submission Comment'
    t 'names.submission_comment_for_teacher', 'Submission Comment For Teacher'
    t 'names.submission_grade_changed', 'Submission Grade Changed'
    t 'names.submission_graded', 'Submission Graded'
    t 'names.summaries', 'Summaries'
    t 'names.updated_wiki_page', 'Updated Wiki Page'
    t 'names.web_conference_invitation', 'Web Conference Invitation'
    t 'names.alert', 'Alert'
    t 'names.appointment_canceled_by_user', 'Appointment Canceled By User'
    t 'names.appointment_deleted_for_user', 'Appointment Deleted For User'
    t 'names.appointment_group_deleted', 'Appointment Group Deleted'
    t 'names.appointment_group_published', 'Appointment Group Published'
    t 'names.appointment_group_updated', 'Appointment Group Updated'
    t 'names.appointment_reserved_by_user', 'Appointment Reserved By User'
    t 'names.appointment_reserved_for_user', 'Appointment Reserved For User'
  end

  # TODO: i18n ... show these anywhere we show the category today
  def category_names
    t 'categories.all_submissions', 'All Submissions'
    t 'categories.announcement', 'Announcement'
    t 'categories.calendar', 'Calendar'
    t 'categories.student_appointment_signups', 'Student Appointment Signups'
    t 'categories.appointment_availability', 'Appointment Availability'
    t 'categories.appointment_signups', 'Appointment Signups'
    t 'categories.appointment_cancelations', 'Appointment Cancelations'
    t 'categories.course_content', 'Course Content'
    t 'categories.discussion', 'Discussion'
    t 'categories.discussion_entry', 'DiscussionEntry'
    t 'categories.due_date', 'Due Date'
    t 'categories.files', 'Files'
    t 'categories.grading', 'Grading'
    t 'categories.grading_policies', 'Grading Policies'
    t 'categories.invitiation', 'Invitation'
    t 'categories.late_grading', 'Late Grading'
    t 'categories.membership_update', 'Membership Update'
    t 'categories.other', 'Other'
    t 'categories.registration', 'Registration'
    t 'categories.migration', 'Migration'
    t 'categories.reminder', 'Reminder'
    t 'categories.submission_comment', 'Submission Comment'
  end

  # Translatable display text to use when representing the category to the user.
  # NOTE: If you add a new notification category, update the mapping file for groupings to show up
  #       on notification preferences page. /app/coffeescripts/notifications/NotificationGroupMappings.coffee
  def category_display_name
    case category
      when 'Announcement'
        t(:announcement_display, 'Announcement')
      when 'Course Content'
        t(:course_content_display, 'Course Content')
      when 'Files'
        t(:files_display, 'Files')
      when 'Discussion'
        t(:discussion_display, 'Discussion')
      when 'DiscussionEntry'
        t(:discussion_entry_display, 'Discussion Entry')
      when 'Due Date'
        t(:due_date_display, 'Due Date')
      when 'Grading'
        t(:grading_display, 'Grading')
      when 'Late Grading'
        t(:late_grading_display, 'Late Grading')
      when 'All Submissions'
        t(:all_submissions_display, 'All Submissions')
      when 'Submission Comment'
        t(:submission_comment_display, 'Submission Comment')
      when 'Grading Policies'
        t(:grading_policies_display, 'Grading Policies')
      when 'Invitation'
        t(:invitation_display, 'Invitation')
      when 'Other'
        t(:other_display, 'Administrative Notifications')
      when 'Calendar'
        t(:calendar_display, 'Calendar')
      when 'Student Appointment Signups'
        t(:student_appointment_display, 'Student Appointment Signups')
      when 'Appointment Availability'
        t(:appointment_availability_display, 'Appointment Availability')
      when 'Appointment Signups'
        t(:appointment_signups_display, 'Appointment Signups')
      when 'Appointment Cancelations'
        t(:appointment_cancelations_display, 'Appointment Cancelations')
      when 'Conversation Message'
        t(:conversation_message_display, 'Conversation Message')
      when 'Added To Conversation'
        t(:added_to_conversation_display, 'Added To Conversation')
      when 'Alert'
        t(:alert_display, 'Alert')
      when 'Membership Update'
        t(:membership_update_display, 'Membership Update')
      when 'Reminder'
        t(:reminder_display, 'Reminder')
      else
        t(:missing_display_display, "For %{category} notifications", :category => category)
    end
  end

  def category_description
    case category
    when 'Announcement'
      t(:announcement_description, "For new announcements")
    when 'Course Content'
      t(:course_content_description, "For changes to course pages and assignments")
    when 'Files'
      t(:files_description, "For new files")
    when 'Discussion'
      t(:discussion_description, "For new topics")
    when 'DiscussionEntry'
      t(:discussion_entry_description, "For topics I've commented on")
    when 'Due Date'
      t(:due_date_description, "For due date changes")
    when 'Grading'
      t(:grading_description, "For course grading alerts")
    when 'Late Grading'
      t(:late_grading_description, "For assignments turned in late")
    when 'All Submissions'
      t(:all_submissions_description, "For all assignment submissions in courses you teach")
    when 'Submission Comment'
      t(:submission_comment_description, "For comments on assignment submissions")
    when 'Grading Policies'
      t(:grading_policies_description, "For course grading policy changes")
    when 'Invitation'
      t(:invitation_description, "For new invitations")
    when 'Other'
      t(:other_description, "For administrative alerts")
    when 'Calendar'
      t(:calendar_description, "For calendar changes")
    when 'Student Appointment Signups'
      t(:student_appointment_description, "For student appointment signups and cancelations")
    when 'Appointment Availability'
      t(:appointment_availability_description, "For changes to appointment time slots")
    when 'Appointment Signups'
      t(:appointment_signups_description, "For your new appointments")
    when 'Appointment Cancelations'
      t(:appointment_cancelations_description, "For canceled appointments")
    when 'Conversation Message'
      t(:conversation_message_description, "For new conversation messages")
    when 'Added To Conversation'
      t(:added_to_conversation_description, "For conversations to which you're added")
    when 'Alert'
      t(:alert_description, "For alert notifications")
    when 'Membership Update'
      t(:membership_update_description, "For membership change notifications")
    when 'Reminder'
      t(:reminder_description, "For reminder messages")
    else
      t(:missing_description_description, "For %{category} notifications", :category => category)
    end
  end

  def display_category
    case category
      when 'Student Appointment Signups', 'Appointment Availability',
           'Appointment Signups', 'Appointment Cancelations'
        'Calendar'
      else
        category
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

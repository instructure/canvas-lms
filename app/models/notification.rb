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
    "Appointment Group Published",
    "Appointment Group Updated",
    "Appointment Reserved For User",
  ].freeze

  FREQ_IMMEDIATELY = 'immediately'
  FREQ_DAILY = 'daily'
  FREQ_WEEKLY = 'weekly'
  FREQ_NEVER = 'never'

  has_many :messages
  has_many :notification_policies, :dependent => :destroy
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
    self.body ||= t(:no_comments, "No comments")
    self.subject ||= t(:no_subject, "No Subject")
    self.sms_body ||= t(:no_comments, "No comments")
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
      message.body = self.sms_body
      message.notification = self
      message.notification_name = self.name
      message.user = user
      message.context = asset
      message.asset_context = opts[:asset_context] || asset.context(user) rescue asset
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
    current_locale = I18n.locale

    tos = tos.flatten.compact.uniq
    if tos.last.is_a? Hash
      options = tos.delete_at(tos.length - 1)
      data = options.delete(:data)
    end
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
    
    recipients += User.find(:all, :conditions => {:id => recipient_ids}, :include => { :communication_channels => :notification_policies})
    
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
        cc = user.email_channel
      end
      I18n.locale = infer_locale(:user => user)
      
      # For non-essential messages, check if too many have gone out, and if so
      # send this message as a daily summary message instead of immediate.
      should_summarize = user && self.summarizable? && too_many_messages?(user)
      channels = CommunicationChannel.find_all_for(user, self, cc)
      fallback_channel = channels.sort_by{|c| c.path_type }.first
      record_delayed_messages((options || {}).merge(:user => user, :communication_channel => cc, :asset => asset, :fallback_channel => should_summarize ? channels.first : nil))
      if should_summarize
        channels = channels.select{|cc| cc.path_type != 'email' && cc.path_type != 'sms' }
      end
      channels << "dashboard" if self.dashboard? && self.show_in_feed?
      channels.clear if !user || (user.pre_registered? && !self.registration?)
      channels.each do |c|
        to_path = c
        to_path = c.path if c.respond_to?("path")

        message = (user || cc || self).messages.build(
          :subject => self.subject, 
          :to => to_path,
          :notification => self
        )

        message.body = self.body
        message.body = self.sms_body if c.respond_to?("path_type") && c.path_type == "sms"
        message.notification_name = self.name
        message.communication_channel = c if c.is_a?(CommunicationChannel)
        message.dispatch_at = nil
        message.user = user
        message.context = asset
        message.asset_context = options[:asset_context] || asset.context(user) rescue asset
        message.notification_category = self.category
        message.delay_for = self.delay_for if self.delay_for 
        message.data = data if data
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

    Message.transaction do
      # Cancel any that haven't been sent out for the same purpose
      all_matching_messages = self.messages.for(asset).by_name(name).for_user(recipients).in_state([:created,:staged,:sending,:dashboard])
      all_matching_messages.update_all(:workflow_state => 'cancelled')
      dispatch_messages.each { |m| m.stage_without_dispatch!; m.save! }
    end
    MessageDispatcher.batch_dispatch(dispatch_messages)

    # re-set cached values
    @user_counts.each{|user_id, cnt| recent_messages_for_user(user_id, cnt) }

    messages
  ensure
    I18n.locale = current_locale
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
  
  def default_frequency
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
    t 'names.assignment_due_date_reminder', 'Assignment Due Date Reminder'
    t 'names.assignment_graded', 'Assignment Graded'
    t 'names.assignment_grading_reminder', 'Assignment Grading Reminder'
    t 'names.assignment_publishing_reminder', 'Assignment Publishing Reminder'
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

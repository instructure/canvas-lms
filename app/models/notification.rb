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

class Notification < Switchman::UnshardedRecord
  include TextHelper

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

    # Mentions
    "Discussion Mention",

    # Testing
    "Show In Feed",
  ].freeze

  ALLOWED_PUSH_NOTIFICATION_CATEGORIES = %w[
    announcement
    appointment_availability
    appointment_cancelations
    calendar
    conversation_message
    course_content
    discussion_mention
    reported_reply
    due_date
    grading
    invitation
    student_appointment_signups
    submission_comment
    discussion
    discussion_entry
  ].freeze

  ALLOWED_PUSH_NOTIFICATION_TYPES = [
    "Annotation Notification",
    "Annotation Teacher Notification",
    "Announcement Reply",
    "Appointment Canceled By User",
    "Appointment Deleted For User",
    "Appointment Group Deleted",
    "Appointment Group Published",
    "Appointment Group Updated",
    "Assignment Changed",
    "Assignment Created",
    "Assignment Due Date Changed",
    "Assignment Due Date Override Changed",
    "Assignment Unmuted",
    "Collaboration Invitation",
    "Conversation Message",
    "Discussion Mention",
    "Reported Reply",
    "Event Date Changed",
    "New Announcement",
    "New Event Created",
    "Peer Review Invitation",
    "Quiz Regrade Finished",
    "Rubric Assessment Submission Reminder",
    "Submission Comment",
    "Submission Comment For Teacher",
    "Submission Grade Changed",
    "Submission Graded",
    "Submission Needs Grading",
    "Upcoming Assignment Alert",
    "Web Conference Invitation",
    "New Discussion Topic",
    "New Discussion Entry"
  ].freeze

  NON_CONFIGURABLE_TYPES = %w[Migration Registration Summaries Alert].freeze

  COURSE_TYPES = [
    # Course Activities
    "Due Date",
    "Grading Policies",
    "Course Content",
    "Files",
    "Announcement",
    "Announcement Created By You",
    "Grading",
    "Invitation",
    "All Submissions",
    "Late Grading",
    "Submission Comment",
    "Blueprint",

    # Discussions
    "Discussion",
    "DiscussionEntry",
    "DiscussionMention",
    "ReportedReply",

    # Scheduling
    "Student Appointment Signups",
    "Appointment Signups",
    "Appointment Cancelations",
    "Appointment Availability",
    "Calendar",

    # Conferences
    "Recording Ready"
  ].freeze

  FREQ_IMMEDIATELY = "immediately"
  FREQ_DAILY = "daily"
  FREQ_WEEKLY = "weekly"
  FREQ_NEVER = "never"

  has_many :messages
  has_many :notification_policies, dependent: :destroy
  has_many :notification_policy_overrides, inverse_of: :notification, dependent: :destroy
  before_save :infer_default_content

  validates :name, uniqueness: true

  after_create { self.class.reset_cache! }

  def self.all_cached
    @all ||= all.to_a.each(&:readonly!)
  end

  def self.valid_configurable_types
    # this is ugly, but reading from file instead of defined notifications in db
    # because this is used to define valid types in our graphql which needs to
    # exists for specs to be able to use any graphql mutation in this space.
    #
    # the file is loaded by category, category_name so first, then last grabs all the types.
    #  we have a deprecated type that we consider invalid
    # graphql types cannot have spaces we have used underscores
    # and we don't allow editing system notification types
    @configurable_types ||= YAML.safe_load(ERB.new(File.read(Canvas::MessageHelper.find_message_path("notification_types.yml"))).result)
                                .pluck("category")
                                .reject { |type| type.include?("DEPRECATED") }
                                .map { |c| c.gsub(/\s/, "_") } - NON_CONFIGURABLE_TYPES
  end

  def self.find(id)
    (@all_by_id ||= all_cached.index_by(&:id))[id.to_i] or raise ActiveRecord::RecordNotFound
  end

  def self.reset_cache!
    @all = nil
    @all_by_id = nil
    if ::Rails.env.test? && !@checked_partition && !ActiveRecord::Base.in_migration
      Messages::Partitioner.process # might have fallen out of date - but we should only check if we're actually running notification specs
      @checked_partition = true
    end
  end

  def duplicate
    notification = clone
    notification.id = id
    notification.send(:remove_instance_variable, :@new_record)
    notification
  end

  def infer_default_content
    self.subject ||= t(:no_subject, "No Subject")
  end
  protected :infer_default_content

  # Public: create (and dispatch, and queue delayed) a message
  #  for this notification, associated with the given asset, sent to the given recipients
  #
  # asset - what the message applies to. An assignment, a discussion, etc.
  # to_list - a list of who to send the message to. the list can contain Users, User ids, or communication channels
  # options - a hash of extra options to merge with the options used to build the Message
  #
  def create_message(asset, to_list, options = {})
    if asset.respond_to?(:account)
      return if asset.account&.root_account&.suppress_notifications?
    end

    if asset.respond_to?(:context) && asset.context.respond_to?(:root_account)
      return if asset.context&.root_account&.suppress_notifications?
    end

    if asset.respond_to?(:context) && asset.context.respond_to?(:account)
      return if asset.context.account&.root_account&.suppress_notifications?
    end

    preload_asset_roles_if_needed(asset)

    NotificationMessageCreator.new(self, asset, options.merge(to_list:)).create_message
  end

  TYPES_TO_PRELOAD_CONTEXT_ROLES = ["Assignment Created", "Assignment Due Date Changed"].freeze
  def preload_asset_roles_if_needed(asset)
    if TYPES_TO_PRELOAD_CONTEXT_ROLES.include?(name)
      case asset
      when Assignment
        ActiveRecord::Associations.preload(asset, :assignment_overrides)
        asset.context.preload_user_roles!
      when AssignmentOverride
        ActiveRecord::Associations.preload(asset.assignment, :assignment_overrides)
        asset.assignment.context.preload_user_roles!
      end
    end
  end

  def sort_order
    case category
    when "Announcement"
      1
    when "Grading"
      3
    when "Late Grading"
      4
    when "Registration"
      5
    when "Invitation"
      6
    when "Grading Policies"
      7
    when "Submission Comment"
      8
    else
      9
    end
  end

  def self.types_to_show_in_feed
    TYPES_TO_SHOW_IN_FEED
  end

  def self.categories_to_send_in_push
    Setting.get("allowed_push_notification_categories", ALLOWED_PUSH_NOTIFICATION_CATEGORIES.join(",")).split(",")
  end

  def self.types_to_send_in_push
    Setting.get("allowed_push_notification_types", ALLOWED_PUSH_NOTIFICATION_TYPES.join(",")).split(",")
  end

  def show_in_feed?
    category == "TestImmediately" || Notification.types_to_show_in_feed.include?(name)
  end

  def is_course_type?
    COURSE_TYPES.include? category
  end

  def registration?
    category == "Registration"
  end

  def migration?
    category == "Migration"
  end

  def summarizable?
    !registration? && !migration?
  end

  def dashboard?
    NON_CONFIGURABLE_TYPES.exclude?(category)
  end

  def category_slug
    (category || "").tr(" ", "_").gsub(/[^\w]/, "").downcase
  end

  # if user is given, categories that aren't relevant to that user will be
  # filtered out.
  def self.dashboard_categories(user = nil)
    seen_types = {}
    res = []
    Notification.all_cached.each do |n|
      if !seen_types[n.category] && (user.nil? || n.relevant_to_user?(user))
        seen_types[n.category] = true
        res << n if n.category && n.dashboard?
      end
    end
    res.sort_by { |n| (n.category == "Other") ? CanvasSort::Last : n.category }
  end

  # Return a hash with information for a related user option if one exists.
  def related_user_setting(user, root_account)
    if user.present? && category == "Grading" && root_account.settings[:allow_sending_scores_in_emails] != false
      {
        name: :send_scores_in_emails,
        value: user.preferences[:send_scores_in_emails],
        label: t(<<~TEXT),
          Include scores when alerting about grades.
          If your email is not an institution email this means sensitive content will be sent outside of the institution.
        TEXT
        id: "cat_#{id}_option",
      }
    end
  end

  def default_frequency(user = nil)
    return FREQ_NEVER if user&.default_notifications_disabled?

    case category
    when "All Submissions",
         "Announcement Created By You",
         "Announcement Reply",
         "Calendar",
         "Course Content",
         "Conversation Created",
         "Discussion",
         "Files",
         "Student Appointment Signups",
         "TestNever"
      FREQ_NEVER
    when "Account Notification",
         "Added To Conversation",
         "Announcement",
         "Appointment Availability",
         "Appointment Signups",
         "Appointment Cancelations",
         "Conversation Message",
         "Grading",
         "Invitation",
         "DiscussionMention",
         "Migration",
         "Recording Ready",
         "Registration",
         "ReportedReply",
         "TestImmediately"
      FREQ_IMMEDIATELY
    when "Due Date",
         "Grading Policies",
         "TestWeekly"
      FREQ_WEEKLY
    else
      # 'Content Link Error',
      # 'DiscussionEntry',
      # 'Late Grading',
      # 'Membership Update',
      # 'Other',
      # 'Reminder',
      # 'Submission Comment',
      # 'TestDaily'
      FREQ_DAILY
    end
  end

  # TODO: i18n: show the localized notification name in the dashboard (or
  # wherever), even if we continue to store the english string in the db
  # (it's actually just the titleized message template filename)
  def names
    t "names.manually_created_access_token_created", "Manually Created Access Token Created"
    t "names.account_user_notification", "Account User Notification"
    t "names.account_user_registration", "Account User Registration"
    t "Annotation Notification"
    t "Annotation Teacher Notification"
    t "names.assignment_changed", "Assignment Changed"
    t "names.assignment_created", "Assignment Created"
    t "names.assignment_due_date_changed", "Assignment Due Date Changed"
    t "names.assignment_due_date_override_changed", "Assignment Due Date Override Changed"
    t "names.assignment_graded", "Assignment Graded"
    t "names.assignment_resubmitted", "Assignment Resubmitted"
    t "names.assignment_submitted", "Assignment Submitted"
    t "names.assignment_submitted_late", "Assignment Submitted Late"
    t "names.collaboration_invitation", "Collaboration Invitation"
    t "names.confirm_email_communication_channel", "Confirm Email Communication Channel"
    t "names.confirm_registration", "Confirm Registration"
    t "names.confirm_sms_communication_channel", "Confirm Sms Communication Channel"
    t "names.content_export_failed", "Content Export Failed"
    t "names.content_export_finished", "Content Export Finished"
    t "Discussion Mention"
    t "Reported Reply"
    t "names.enrollment_accepted", "Enrollment Accepted"
    t "names.enrollment_invitation", "Enrollment Invitation"
    t "names.enrollment_notification", "Enrollment Notification"
    t "names.enrollment_registration", "Enrollment Registration"
    t "names.event_date_changed", "Event Date Changed"
    t "names.forgot_password", "Forgot Password"
    t "names.grade_weight_changed", "Grade Weight Changed"
    t "names.group_assignment_submitted_late", "Group Assignment Submitted Late"
    t "names.group_membership_accepted", "Group Membership Accepted"
    t "names.group_membership_rejected", "Group Membership Rejected"
    t "names.merge_email_communication_channel", "Merge Email Communication Channel"
    t "names.migration_import_failed", "Migration Import Failed"
    t "names.migration_import_finished", "Migration Import Finished"
    t "names.new_account_user", "New Account User"
    t "names.new_announcement", "New Announcement"
    t "names.announcement_created_by_you", "Announcement Created By You"
    t "names.announcement_reply", "Announcement Reply"
    t "names.new_context_group_membership", "New Context Group Membership"
    t "names.new_context_group_membership_invitation", "New Context Group Membership Invitation"
    t "names.new_course", "New Course"
    t "names.new_discussion_entry", "New Discussion Entry"
    t "names.new_discussion_topic", "New Discussion Topic"
    t "names.new_event_created", "New Event Created"
    t "names.new_file_added", "New File Added"
    t "names.new_files_added", "New Files Added"
    t "names.new_student_organized_group", "New Student Organized Group"
    t "names.new_user", "New User"
    t "names.pseudonym_registration", "Pseudonym Registration"
    t "names.pseudonym_registration_done", "Pseudonym Registration Done"
    t "names.report_generated", "Report Generated"
    t "names.report_generation_failed", "Report Generation Failed"
    t "names.rubric_assessment_invitation", "Rubric Assessment Invitation"
    t "names.rubric_assessment_submission_reminder", "Rubric Assessment Submission Reminder"
    t "names.rubric_association_created", "Rubric Association Created"
    t "names.conversation_message", "Conversation Message"
    t "names.added_to_conversation", "Added To Conversation"
    t "names.conversation_created", "Conversation Created"
    t "names.submission_comment", "Submission Comment"
    t "names.submission_comment_for_teacher", "Submission Comment For Teacher"
    t "names.submission_grade_changed", "Submission Grade Changed"
    t "names.submission_graded", "Submission Graded"
    t "names.summaries", "Summaries"
    t "names.updated_wiki_page", "Updated Page"
    t "names.web_conference_invitation", "Web Conference Invitation"
    t "names.alert", "Alert"
    t "names.appointment_canceled_by_user", "Appointment Canceled By User"
    t "names.appointment_deleted_for_user", "Appointment Deleted For User"
    t "names.appointment_group_deleted", "Appointment Group Deleted"
    t "names.appointment_group_published", "Appointment Group Published"
    t "names.appointment_group_updated", "Appointment Group Updated"
    t "names.appointment_reserved_by_user", "Appointment Reserved By User"
    t "names.appointment_reserved_for_user", "Appointment Reserved For User"
    t "names.submission_needs_grading", "Submission Needs Grading"
    t "names.web_conference_recording_ready", "Web Conference Recording Ready"
    t "names.blueprint_sync_complete", "Blueprint Sync Complete"
    t "names.blueprint_content_added", "Blueprint Content Added"
    t "names.content_link_error", "Content Link Error"
    t "names.account_notification", "Account Notification"
    t "names.upcoming_assignment_alert", "Upcoming Assignment Alert"
  end

  # TODO: i18n ... show these anywhere we show the category today
  def category_names
    t "categories.all_submissions", "All Submissions"
    t "categories.announcement", "Announcement"
    t "categories.calendar", "Calendar"
    t "categories.student_appointment_signups", "Student Appointment Signups"
    t "categories.appointment_availability", "Appointment Availability"
    t "categories.appointment_signups", "Appointment Signups"
    t "categories.appointment_cancelations", "Appointment Cancellations"
    t "categories.course_content", "Course Content"
    t "categories.discussion", "Discussion"
    t "categories.discussion_entry", "DiscussionEntry"
    t "DiscussionMention"
    t "ReportedReply"
    t "categories.due_date", "Due Date"
    t "categories.files", "Files"
    t "categories.grading", "Grading"
    t "categories.grading_policies", "Grading Policies"
    t "categories.invitiation", "Invitation"
    t "categories.late_grading", "Late Grading"
    t "categories.membership_update", "Membership Update"
    t "categories.other", "Other"
    t "categories.registration", "Registration"
    t "categories.migration", "Migration"
    t "categories.reminder", "Reminder"
    t "categories.submission_comment", "Submission Comment"
    t "categories.recording_ready", "Recording Ready"
    t "categories.blueprint", "Blueprint"
    t "categories.content_link_error", "Content Link Error"
    t "categories.account_notification", "Account Notification"
  end

  # Translatable display text to use when representing the category to the user.
  # NOTE: If you add a new notification category, update the mapping file for groupings to show up
  #       on notification preferences page. ui/features/notification_preferences/jquery/NotificationGroupMappings.js
  def category_display_name
    case category
    when "Announcement"
      t(:announcement_display, "Announcement")
    when "Announcement Created By You"
      t(:announcement_created_by_you_display, "Announcement Created By You")
    when "Course Content"
      t(:course_content_display, "Course Content")
    when "Files"
      t(:files_display, "Files")
    when "Discussion"
      t(:discussion_display, "New Topic")
    when "DiscussionEntry"
      t(:discussion_post_display, "New Reply")
    when "DiscussionMention"
      t("New Mention")
    when "ReportedReply"
      t("Reported Reply")
    when "Due Date"
      t(:due_date_display, "Due Date")
    when "Grading"
      t(:grading_display, "Grading")
    when "Late Grading"
      t(:late_grading_display, "Late Grading")
    when "All Submissions"
      t(:all_submissions_display, "All Submissions")
    when "Submission Comment"
      t(:submission_comment_display, "Submission Comment")
    when "Grading Policies"
      t(:grading_policies_display, "Grading Policies")
    when "Invitation"
      t(:invitation_display, "Invitation")
    when "Other"
      t(:other_display, "Administrative Notifications")
    when "Calendar"
      t(:calendar_display, "Calendar")
    when "Student Appointment Signups"
      t(:student_appointment_display, "Student Appointment Signups")
    when "Appointment Availability"
      t(:appointment_availability_display, "Appointment Availability")
    when "Appointment Signups"
      t(:appointment_signups_display, "Appointment Signups")
    when "Appointment Cancelations"
      t(:appointment_cancelations_display, "Appointment Cancellations")
    when "Conversation Message"
      t(:conversation_message_display, "Conversation Message")
    when "Added To Conversation"
      t(:added_to_conversation_display, "Added To Conversation")
    when "Conversation Created"
      t(:conversation_created_display, "Conversations Created By Me")
    when "Membership Update"
      t(:membership_update_display, "Membership Update")
    when "Reminder"
      t(:reminder_display, "Reminder")
    when "Recording Ready"
      t(:recording_ready_display, "Recording Ready")
    when "Blueprint"
      t(:blueprint_display, "Blueprint Sync")
    when "Content Link Error"
      t(:content_link_error_display, "Content Link Error")
    when "Account Notification"
      t(:account_notification_display, "Global Announcements")
    else
      t(:missing_display_display, "For %{category} notifications", category:)
    end
  end

  def category_description
    case category
    when "Announcement"
      t(:announcement_description, "New Announcement in your course")
    when "Announcement Created By You"
      mt(:announcement_created_by_you_description, <<~MD)
        * Announcements created by you
        * Replies to announcements you've created
      MD
    when "Course Content"
      mt(:course_content_description, <<~MD)
        Change to course content:

        * Page content
        * Quiz content
        * Assignment content
      MD
    when "Files"
      t(:files_description, "New file added to your course")
    when "Discussion"
      t(:discussion_description, "New Discussion topic in your course")
    when "DiscussionEntry"
      t(:discussion_post_description, "New reply on a topic you're subscribed to")
    # Remove the feature flag explanation when :react_discussions_post feature flag is removed
    when "DiscussionMention"
      mt(:discussion_mention_description, <<~MD)
        New Mention in a Discussion.

        *Discussion Mentions are only available
        for courses or accounts that have the
        Discussions/Announcements Redesign
        feature flag turned on.*
      MD
    when "ReportedReply"
      t(:reported_reply_description, "New reported reply in a Discussion")
    when "Due Date"
      t(:due_date_description, "Assignment due date change")
    when "Grading"
      mt(:grading_description, <<~MD)
        Includes:

        * Assignment/submission grade entered/changed
        * Grade weight changed
      MD
    when "Late Grading"
      mt(:late_grading_description, <<~MD)
        *Instructor and Admin only:*

        Late assignment submission
      MD
    when "All Submissions"
      mt(:all_submissions_description, <<~MD)
        *Instructor and Admin only:*

        Assignment (except quizzes) submission/resubmission
      MD
    when "Submission Comment"
      t(:submission_comment_description, "Assignment submission comment")
    when "Grading Policies"
      t(:grading_policies_description, "Course grading policy change")
    when "Invitation"
      mt(:invitation_description, <<~MD)
        Invitation for:

        * Web conference
        * Group
        * Collaboration
        * Peer Review & reminder
      MD
    when "Other"
      mt(:other_description, <<~MD)
        *Instructor and Admin only:*

        * Course enrollment
        * Report generated
        * Content export
        * Migration report
        * New account user
        * New student group
      MD
    when "Calendar"
      t(:calendar_description, "New and changed items on your course calendar")
    when "Student Appointment Signups"
      mt(:student_appointment_description, <<~MD)
        *Instructor and Admin only:*

        Student appointment sign-up
      MD
    when "Appointment Availability"
      t("New appointment timeslots are available for signup")
    when "Appointment Signups"
      t(:appointment_signups_description, "New appointment on your calendar")
    when "Appointment Cancelations"
      t(:appointment_cancelations_description, "Appointment cancellation")
    when "Conversation Message"
      t(:conversation_message_description, "New Inbox messages")
    when "Added To Conversation"
      t(:added_to_conversation_description, "You are added to a conversation")
    when "Conversation Created"
      t(:conversation_created_description, "You created a conversation")
    when "Recording Ready"
      t(:web_conference_recording_ready, "A conference recording is ready")
    when "Membership Update"
      mt(:membership_update_description, <<~MD)
        *Admin only: pending enrollment activated*

        * Group enrollment
        * accepted/rejected
      MD
    when "Blueprint"
      mt(:blueprint_description, <<~MD)
        *Instructor and Admin only:*

        Content was synced from a blueprint course to associated courses
      MD
    when "Content Link Error"
      mt(:content_link_error_description, <<~MD)
        *Instructor and Admin only:*

        Location and content of a failed link that a student has interacted with
      MD
    when "Account Notification"
      mt(:account_notification_description, <<~MD)
        Institution-wide announcements (also displayed on Dashboard pages)
      MD
    else
      t(:missing_description_description, "For %{category} notifications", category:)
    end
  end

  def display_category
    case category
    when "Student Appointment Signups", "Appointment Availability",
           "Appointment Signups", "Appointment Cancelations"
      "Calendar"
    else
      category
    end
  end

  def type_name
    category
  end

  def relevant_to_user?(user)
    case category
    when "All Submissions", "Late Grading"
      user.teacher_enrollments.count > 0 || user.ta_enrollments.count > 0
    when "Added To Conversation", "Conversation Message", "Conversation Created"
      !user.disabled_inbox?
    else
      true
    end
  end
end

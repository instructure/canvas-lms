#
# Copyright (C) 2015 - present Instructure, Inc.
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

class LiveEventsObserver < ActiveRecord::Observer
  observe :content_export,
          :course,
          :discussion_entry,
          :discussion_topic,
          :enrollment,
          :enrollment_state,
          :group,
          :group_category,
          :group_membership,
          :wiki_page,
          :assignment,
          :submission,
          :attachment,
          :user,
          :user_account_association,
          :account_notification,
          :course_section,
          :context_module,
          :content_tag

  NOP_UPDATE_FIELDS = [ "updated_at", "sis_batch_id" ].freeze
  def after_update(obj)
    changes = obj.saved_changes
    return nil if changes.except(*NOP_UPDATE_FIELDS).empty?

    obj.class.connection.after_transaction_commit do
    case obj
    when ContentExport
      if obj.quizzes2_export? && changes["workflow_state"]
        if obj.workflow_state == "exported"
          Canvas::LiveEvents.quiz_export_complete(obj)
        end
      end
    when Course
      if changes["syllabus_body"]
        Canvas::LiveEvents.course_syllabus_updated(obj, changes["syllabus_body"].first)
      end
      Canvas::LiveEvents.course_updated(obj)
    when Enrollment
      Canvas::LiveEvents.enrollment_updated(obj)
    when EnrollmentState
      Canvas::LiveEvents.enrollment_state_updated(obj)
    when GroupCategory
      Canvas::LiveEvents.group_category_updated(obj)
    when Group
      Canvas::LiveEvents.group_updated(obj)
    when GroupMembership
      Canvas::LiveEvents.group_membership_updated(obj)
    when WikiPage
      if changes["title"] || changes["body"]
        Canvas::LiveEvents.wiki_page_updated(obj, changes["title"] ? changes["title"].first : nil,
                                                  changes["body"] ? changes["body"].first : nil)
      end
    when Assignment
      Canvas::LiveEvents.assignment_updated(obj)
    when Attachment
      if attachment_eligible?(obj)
        if changes["display_name"]
          Canvas::LiveEvents.attachment_updated(obj, changes["display_name"].first)
        elsif changes["file_state"] && obj.file_state == 'deleted'
          # Attachments are often soft deleted rather than destroyed
          Canvas::LiveEvents.attachment_deleted(obj)
        end
      end
    when Submission
      if obj.just_submitted?
        Canvas::LiveEvents.submission_created(obj)
      elsif !obj.unsubmitted?
        Canvas::LiveEvents.submission_updated(obj)
      end
    when User
      Canvas::LiveEvents.user_updated(obj)
    when CourseSection
      Canvas::LiveEvents.course_section_updated(obj)
    when ContextModule
      Canvas::LiveEvents.module_updated(obj)
    when ContentTag
      Canvas::LiveEvents.module_item_updated(obj) if obj.tag_type == "context_module"
    end
    end
  end

  def after_create(obj)
    obj.class.connection.after_transaction_commit do
    case obj
    when Course
      Canvas::LiveEvents.course_created(obj)
    when DiscussionEntry
      Canvas::LiveEvents.discussion_entry_created(obj)
    when DiscussionTopic
      Canvas::LiveEvents.discussion_topic_created(obj)
    when Enrollment
      Canvas::LiveEvents.enrollment_created(obj)
    when EnrollmentState
      Canvas::LiveEvents.enrollment_state_created(obj)
    when Group
      Canvas::LiveEvents.group_created(obj)
    when GroupCategory
      Canvas::LiveEvents.group_category_created(obj)
    when GroupMembership
      Canvas::LiveEvents.group_membership_created(obj)
    when WikiPage
      Canvas::LiveEvents.wiki_page_created(obj)
    when Assignment
      Canvas::LiveEvents.assignment_created(obj)
    when Submission
      Canvas::LiveEvents.submission_created(obj)
    when UserAccountAssociation
      Canvas::LiveEvents.user_account_association_created(obj)
    when Attachment
      if attachment_eligible?(obj)
        Canvas::LiveEvents.attachment_created(obj)
      end
    when AccountNotification
      Canvas::LiveEvents.account_notification_created(obj)
    when User
      Canvas::LiveEvents.user_created(obj)
    when CourseSection
      Canvas::LiveEvents.course_section_created(obj)
    when ContextModule
      Canvas::LiveEvents.module_created(obj)
    when ContentTag
      Canvas::LiveEvents.module_item_created(obj) if obj.tag_type == "context_module"
    end
    end
  end

  def after_destroy(obj)
    obj.class.connection.after_transaction_commit do
    case obj
    when Attachment
      if attachment_eligible?(obj)
        Canvas::LiveEvents.attachment_deleted(obj)
      end
    when WikiPage
      Canvas::LiveEvents.wiki_page_deleted(obj)
    end
    end
  end

  private

  ELIGIBLE_ATTACHMENT_CONTEXTS = [ 'Course', 'Group', 'User' ].freeze
  def attachment_eligible?(attachment)
    # We only send live events for attachments that would show up in Files
    # sections of Canvas.
    ELIGIBLE_ATTACHMENT_CONTEXTS.include?(attachment.context_type) &&
      attachment.folder_id.present?
  end
end

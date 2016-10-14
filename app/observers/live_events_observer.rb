class LiveEventsObserver < ActiveRecord::Observer
  observe :course,
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
          :user_account_association

  def after_update(obj)
    changes = obj.changes
    obj.class.connection.after_transaction_commit do
    case obj
    when Course
      if changes["syllabus_body"]
        Canvas::LiveEvents.course_syllabus_updated(obj, changes["syllabus_body"].first)
      end
    when Enrollment
      Canvas::LiveEvents.enrollment_updated(obj)
    when EnrollmentState
      Canvas::LiveEvents.enrollment_state_updated(obj)
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
      Canvas::LiveEvents.submission_updated(obj)
    end
    end
  end

  def after_create(obj)
    obj.class.connection.after_transaction_commit do
    case obj
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

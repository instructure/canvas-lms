class LiveEventsObserver < ActiveRecord::Observer
  observe :course,
          :discussion_entry,
          :discussion_topic,
          :group,
          :group_category,
          :group_membership,
          :wiki_page

  def after_update(obj)
    case obj
    when Course
      if obj.syllabus_body_changed?
        Canvas::LiveEvents.course_syllabus_updated(obj, obj.syllabus_body_was)
      end
    when WikiPage
      if obj.title_changed? || obj.body_changed?
        Canvas::LiveEvents.wiki_page_updated(obj, obj.title_changed? ? obj.title_was : nil,
                                                  obj.body_changed? ? obj.body_was : nil)
      end
    end
  end

  def after_create(obj)
    case obj
    when DiscussionEntry
      Canvas::LiveEvents.discussion_entry_created(obj)
    when DiscussionTopic
      Canvas::LiveEvents.discussion_topic_created(obj)
    when Group
      Canvas::LiveEvents.group_created(obj)
    when GroupCategory
      Canvas::LiveEvents.group_category_created(obj)
    when GroupMembership
      Canvas::LiveEvents.group_membership_created(obj)
    when WikiPage
      Canvas::LiveEvents.wiki_page_created(obj)
    end
  end

  def after_save(obj)
  end

  def after_destroy(obj)
    case obj
    when WikiPage
      Canvas::LiveEvents.wiki_page_deleted(obj)
    end
  end
end

module DiscussionTopicsHelper
  def topic_page_title(topic)
    if @topic.is_announcement
      if @topic.new_record?
        t("#title.new_announcement", "New Announcement")
      else
        t("#title.edit_announcement", "Edit Announcement")
      end
    else
      if @topic.new_record?
        t("#title.new_topic", "New Discussion Topic")
      else
        t("#title.edit_topic", "Edit Discussion Topic")
      end
    end
  end
end

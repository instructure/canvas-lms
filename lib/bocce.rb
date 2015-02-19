module Bocce
  def self.urlize(id, title)
    [id, title.downcase.gsub(' ', '-').gsub(/[^a-z0-9-]/, '_')].join('-')
  end

  def self.find_lesson_number(course, type, id)
    course.context_modules.select do |mod|
      mod.content_tags.select { |ct| ct.content_type == type && ct.content_id = id }.first
    end.first.position - 1
  end

  def self.link(asset)
    # A few that always run, to convert to types we actually want to deal with
    if asset.kind_of? DiscussionEntry
      asset = asset.discussion_topic
    end

    if asset.kind_of? SubmissionComment
      asset = asset.submission
    end

    if asset.kind_of? ConversationMessage
      asset = asset.conversation
    end

    if asset.kind_of? Submission
      assignment = asset.assignment
      course = assignment.context

      lesson_num = Bocce.find_lesson_number(course, 'Assignment', assignment.id)

      obj_url = "/#{lesson_num}/#{Bocce.urlize(assignment.id, assignment.title)}/submission/#{asset.id}_#{asset.user_id}"
    elsif asset.kind_of? DiscussionTopic
      course = asset.course

      obj_url = "/-1/-1/discussion/#{Bocce.urlize(asset.id, asset.title)}"
    elsif asset.kind_of? Conversation
      course = asset.context

      # Conversations are created (always?) outside of courses.  Look at the 
      # participants and try to guess what course they're both in .
      if course.blank? || ! course.kind_of?(Course)
        user_a_courses = asset.participants[0].enrollments.map(&:course_id).sort.reverse

        course_id = nil

        if asset.participants.length > 1
          user_b_courses = asset.participants[1].enrollments.map(&:course_id).sort.reverse

          course_id = (user_a_courses & user_b_courses).last
        end

        if course_id.blank?
          course_id = user_a_courses.last
        end

        course = Course.find(course_id)
      end

      obj_url = "/-1/-1/conversation/#{asset.id}"
    else
      Rails.logger.info "Unknown asset type in notifier"
      Rails.logger.info asset.inspect

      return ""
    end

    section = course.course_sections.first

    "#/#{course.id}/#{course.course_code}/#{section.id}#{obj_url}"
  end
end

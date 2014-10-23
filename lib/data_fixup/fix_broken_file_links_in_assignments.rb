module DataFixup::FixBrokenFileLinksInAssignments

  def self.broken_assignment_scope
    # This date is the date that g/16823 was deployed to beta and production
    Assignment.where(["context_type = ? AND updated_at > ? AND
      (description LIKE ? OR description LIKE ? OR description LIKE ?)",
      "Course", "2013-03-08", "%verifier%", "%'/files/%", "%\"/files/%"])
  end

  def self.run
    broken_assignment_scope.find_in_batches do |assignments|
      # When the topic is saved it can't find the assignment because the
      # find_in_batches scope is still in effect, make it have an exclusive scope
      assignments.each do |assignment|
        check_and_fix_assignment_description(assignment)
      end
    end
  end

  COURSE_FILES_REGEX = %r{\A/courses/\d+/files/(\d+)/download}
  FILES_REGEX = %r{\A/files/(\d+)/download}

  # see spec for examples of how the urls are changed
  def self.check_and_fix_assignment_description(assignment)
    attrs = ['href', 'src']
    changed = false
    doc = Nokogiri::HTML(assignment.description)

    doc.search("*").each do |node|
      attrs.each do |attr|
        if node[attr]
          course_id = nil
          file_id = nil

          if node[attr] =~ COURSE_FILES_REGEX
            file_id = $1
          elsif node[attr] =~ FILES_REGEX
            file_id = $1
          end

          if file_id
            if att = Attachment.where(id: file_id).first
              # this find returns the passed in att if nothing found in the context
              # and sometimes URI.unescape errors so ignore that
              att = att.context.attachments.find(att.id) rescue att
              if att.context_type == "Course" && att.context_id == assignment.context_id
                course_id = assignment.context_id
                file_id = att.id
              elsif att.cloned_item_id && cloned_att = assignment.context.attachments.where(cloned_item_id: att.cloned_item_id).first
                course_id = assignment.context_id
                file_id = assignment.context.attachments.find(cloned_att.id).id rescue cloned_att.id
              elsif att.context_type == "Course"
                course_id = att.context_id
              end
            end
          end

          if course_id
            if assignment.context_id == course_id.to_i
              node[attr] = "/courses/#{course_id}/files/#{file_id}/download?wrap=1"
              changed = true
            elsif node[attr] =~ FILES_REGEX
              node[attr] = node[attr].sub("/files/#{file_id}", "/courses/#{course_id}/files/#{file_id}")
              changed = true
            end
          end
        end
      end
    end

    if changed
      Assignment.where(:id => assignment).update_all(:description => doc.at_css('body').inner_html)
    end
  rescue
    Rails.logger.error "FixBrokenFileLinksInAssignments couldn't fix #{assignment.id}"
  end
end
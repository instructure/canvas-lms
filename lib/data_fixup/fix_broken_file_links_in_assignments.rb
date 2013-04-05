module DataFixup::FixBrokenFileLinksInAssignments
  def self.run
    Assignment.where(["context_type = ? AND updated_at > ? AND
      (description LIKE ? OR description LIKE ? OR description LIKE ?)",
      "Course", "2013-03-08", "%verifier%", "%'/files/", "%\"/files/"]).find_in_batches do |assignments|
      # This date is the date that g/16823 was deployed to beta and production
      assignments.each do |assignment|
        check_and_fix_assignment_description(assignment)
      end
    end
  end

  COURSE_FILES_REGEX = %r{\A/courses/\d+/files/(\d+)/download}
  FILES_REGEX = %r{\A/files/(\d+)/download}

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
            if att = Attachment.find_by_id(file_id)
              att = att.context.attachments.find(att.id)
              if att.context_type == "Course" && att.context_id == assignment.context_id
                course_id = assignment.context_id
                file_id = att.id
              elsif att.cloned_item_id && cloned_att = assignment.context.attachments.find_by_cloned_item_id(att.cloned_item_id)
                course_id = assignment.context_id
                file_id = assignment.context.attachments.find(cloned_att.id).id
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
      assignment.description = doc.at_css('body').inner_html
      assignment.save!
    end
  end
end
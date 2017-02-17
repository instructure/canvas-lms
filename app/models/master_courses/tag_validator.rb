class MasterCourses::TagValidator < ActiveModel::Validator
  # never used one of these before, not really sure why i'm starting now

  def validate(record)
    if record.new_record?
      unless MasterCourses::ALLOWED_CONTENT_TYPES.include?(record.content_type)
        record.errors[:content] << "Invalid content"
      end
    elsif record.content_id_changed? || record.content_type_changed? # apparently content_changed? didn't work at all - i must have been smoking something
      record.errors[:content] << "Cannot change content" # don't allow changes to content after creation
    end
  end
end

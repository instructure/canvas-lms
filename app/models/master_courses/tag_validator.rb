class MasterCourses::TagValidator < ActiveModel::Validator
  # never used one of these before, not really sure why i'm starting now

  def validate(record)
    if record.new_record?
      unless MasterCourses::ALLOWED_CONTENT_TYPES.include?(record.content_type)
        record.errors[:content] << "Invalid content"
      end
    elsif record.content_changed?
      record.errors[:content] << "Cannot change content" # don't allow changes to content after creation
    end
  end
end

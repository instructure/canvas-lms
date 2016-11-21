module DataFixup::ResanitizeAssignmentsAllowedExtensions
  def self.run
    Assignment.where(["allowed_extensions IS NOT NULL AND updated_at > ?", "2013-03-08"]).find_each do |assignment|
      assignment.allowed_extensions = assignment.allowed_extensions
      Assignment.where(id: assignment).update_all(
        allowed_extensions: assignment.allowed_extensions
      )
    end
  end
end

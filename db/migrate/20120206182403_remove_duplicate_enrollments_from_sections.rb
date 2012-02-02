class RemoveDuplicateEnrollmentsFromSections < ActiveRecord::Migration
  self.transactional = false

  def self.up
    count = Enrollment.remove_duplicate_enrollments_from_sections
    say "Deleted #{count} duplicate enrollments"
  end

  def self.down
  end
end

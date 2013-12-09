class RemoveDuplicateEnrollmentsFromSections < ActiveRecord::Migration
  disable_ddl_transaction!

  def self.up
    count = Enrollment.remove_duplicate_enrollments_from_sections
    say "Deleted #{count} duplicate enrollments"
  end

  def self.down
  end
end

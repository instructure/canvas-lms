class RemoveDuplicateEnrollmentsFromSections < ActiveRecord::Migration
  def self.up
    if supports_ddl_transactions?
      commit_db_transaction
      decrement_open_transactions while open_transactions > 0
    end

    count = Enrollment.remove_duplicate_enrollments_from_sections
    say "Deleted #{count} duplicate enrollments"

    if supports_ddl_transactions?
      increment_open_transactions
      begin_db_transaction
    end
  end

  def self.down
  end
end

class RestoreUsersSortableName < ActiveRecord::Migration
  def self.up
    if supports_ddl_transactions?
      commit_db_transaction
      decrement_open_transactions while open_transactions > 0
    end
    User.find_in_batches do |batch|
      User.transaction do
        batch.each do |user|
          user.sortable_name = nil
          user.sortable_name
          User.update_all({ :sortable_name => user.sortable_name }, :id => user.id) if user.changed?
        end
      end
    end
    if supports_ddl_transactions?
      increment_open_transactions
      begin_db_transaction
    end
  end

  def self.down
  end
end

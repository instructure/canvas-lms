class RemoveAttachmentsWithNoScopeFromList < ActiveRecord::Migration
  def self.up
    if supports_ddl_transactions?
      commit_db_transaction
      decrement_open_transactions while open_transactions > 0
    end

    if Attachment.maximum(:id)
      i = 0
      # we do one extra loop to avoid race conditions
      while i < Attachment.maximum(:id) + 10000
        Attachment.update_all({:position => nil}, ["folder_id IS NULL AND id>? AND id <=?", i, i + 10000])
        sleep 1
        i = i + 10000
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

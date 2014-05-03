class RemoveAttachmentsWithNoScopeFromList < ActiveRecord::Migration
  disable_ddl_transaction!

  def self.up
    if Attachment.maximum(:id)
      i = 0
      # we do one extra loop to avoid race conditions
      while i < Attachment.maximum(:id) + 10000
        Attachment.where("folder_id IS NULL AND id>? AND id <=?", i, i + 10000).update_all(:position => nil)
        sleep 1
        i = i + 10000
      end
    end
  end

  def self.down
  end
end

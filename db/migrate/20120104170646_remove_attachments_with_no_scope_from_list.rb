class RemoveAttachmentsWithNoScopeFromList < ActiveRecord::Migration
  self.transactional = false

  def self.up
    if Attachment.maximum(:id)
      i = 0
      # we do one extra loop to avoid race conditions
      while i < Attachment.maximum(:id) + 10000
        Attachment.update_all({:position => nil}, ["folder_id IS NULL AND id>? AND id <=?", i, i + 10000])
        sleep 1
        i = i + 10000
      end
    end
  end

  def self.down
  end
end

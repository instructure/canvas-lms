class DropEnrollmentIdFromAttachments < ActiveRecord::Migration
  def self.up
    remove_index :attachments, [:enrollment_id]
    remove_column :attachments, :enrollment_id
  end

  def self.down
    add_column :attachments, :enrollment_id, :integer, :limit => 8
    add_index :attachments, [:enrollment_id]
  end
end

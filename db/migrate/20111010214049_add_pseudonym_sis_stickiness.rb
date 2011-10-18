class AddPseudonymSisStickiness < ActiveRecord::Migration
  def self.up
    add_column :pseudonyms, :stuck_sis_fields, :text
    execute("UPDATE pseudonyms SET stuck_sis_fields='unique_id' WHERE sis_source_id<>unique_id")
  end

  def self.down
    drop_column :pseudonyms, :stuck_sis_fields
  end
end

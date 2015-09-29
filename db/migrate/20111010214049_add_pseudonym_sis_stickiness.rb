class AddPseudonymSisStickiness < ActiveRecord::Migration
  def self.up
    add_column :pseudonyms, :stuck_sis_fields, :text
    Pseudonym.where("sis_source_id<>unique_id").update_all(stuck_sis_fields: 'unique_id')
  end

  def self.down
    drop_column :pseudonyms, :stuck_sis_fields
  end
end

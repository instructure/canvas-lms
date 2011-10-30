class DropSisSourceIdFromPseudonyms < ActiveRecord::Migration
  def self.up
    remove_column :pseudonyms, :sis_source_id
  end

  def self.down
    add_column :pseudonyms, :sis_source_id, :string
    Pseudonym.update_all('sis_source_id=unique_id', "sis_user_id IS NOT NULL")
  end
end

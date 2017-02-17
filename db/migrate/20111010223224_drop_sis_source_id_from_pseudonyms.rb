class DropSisSourceIdFromPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_column :pseudonyms, :sis_source_id
  end

  def self.down
    add_column :pseudonyms, :sis_source_id, :string
    Pseudonym.where("sis_user_id IS NOT NULL").update_all('sis_source_id=unique_id')
  end
end

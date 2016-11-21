class DropDeletedUniqueIdFromPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Pseudonym.where("deleted_unique_id IS NOT NULL AND workflow_state='deleted'").update_all('unique_id=deleted_unique_id')
    remove_column :pseudonyms, :deleted_unique_id
  end

  def self.down
    add_column :pseudonyms, :deleted_unique_id, :string
    Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all('deleted_unique_id=unique_id')
    Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all("unique_id=unique_id || '--' || SUBSTR(CAST(RANDOM() AS varchar), 3, 4)")
  end
end

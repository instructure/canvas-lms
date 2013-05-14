class DropDeletedUniqueIdFromPseudonyms < ActiveRecord::Migration
  def self.up
    Pseudonym.where("deleted_unique_id IS NOT NULL AND workflow_state='deleted'").update_all('unique_id=deleted_unique_id')
    remove_column :pseudonyms, :deleted_unique_id
  end

  def self.down
    add_column :pseudonyms, :deleted_unique_id, :string
    Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all('deleted_unique_id=unique_id')
    if %w{MySQL Mysql2}.include?(Pseudonym.connection.adapter_name)
      Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all("unique_id=unique_id || '--' || SUBSTR(RAND(), 3, 4)")
    else
      Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all("unique_id=unique_id || '--' || SUBSTR(CAST(RANDOM() AS varchar), 3, 4)")
    end
  end
end

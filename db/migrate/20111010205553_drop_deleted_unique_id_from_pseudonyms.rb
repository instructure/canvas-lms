class DropDeletedUniqueIdFromPseudonyms < ActiveRecord::Migration
  def self.up
    Pseudonym.update_all('unique_id=deleted_unique_id', "deleted_unique_id IS NOT NULL AND workflow_state='deleted'")
    remove_column :pseudonyms, :deleted_unique_id
  end

  def self.down
    add_column :pseudonyms, :deleted_unique_id, :string
    Pseudonym.update_all('deleted_unique_id=unique_id', "unique_id IS NOT NULL AND workflow_state='deleted'")
    if %w{MySQL Mysql2}.include?(Pseudonym.connection.adapter_name)
      Pseudonym.update_all("unique_id=unique_id || '--' || SUBSTR(RAND(), 3, 4)", "unique_id IS NOT NULL AND workflow_state='deleted'")
    else
      Pseudonym.update_all("unique_id=unique_id || '--' || SUBSTR(CAST(RANDOM() AS varchar), 3, 4)", "unique_id IS NOT NULL AND workflow_state='deleted'")
    end
  end
end

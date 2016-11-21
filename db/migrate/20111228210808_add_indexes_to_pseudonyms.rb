class AddIndexesToPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :pseudonyms, :unique_id
      connection.execute("CREATE INDEX index_pseudonyms_on_unique_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id))")
    end
    add_index :pseudonyms, :sis_user_id
  end

  def self.down
    remove_index :pseudonyms, :sis_user_id
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP INDEX index_pseudonyms_on_unique_id")
      add_index :pseudonyms, :unique_id
    end
  end
end

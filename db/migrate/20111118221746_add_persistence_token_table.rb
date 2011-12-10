class AddPersistenceTokenTable < ActiveRecord::Migration
  def self.up
    create_table :session_persistence_tokens do |t|
      t.string :token_salt
      t.string :crypted_token
      t.integer :pseudonym_id, :limit => 8
      t.timestamps
    end
    add_index :session_persistence_tokens, :pseudonym_id
  end

  def self.down
    drop_table :session_persistence_tokens
  end
end

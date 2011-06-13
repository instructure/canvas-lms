class CreateAccessTokens < ActiveRecord::Migration
  def self.up
    create_table :access_tokens do |t|
      t.integer :developer_key_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.string :token
      t.datetime :last_used_at
      t.datetime :expires_at
      t.string :purpose
      t.timestamps
    end
    add_index :access_tokens, [:token], :unique => true

    # developer_key.user_id was a string instead of an integer
    add_column :developer_keys, :user_id_int, :integer, :limit => 8
    if connection.adapter_name =~ /\Apostgres/i
      execute <<-SQL
        UPDATE developer_keys SET user_id_int = CAST(user_id AS INTEGER) WHERE user_id IS NOT NULL
      SQL
    else
      execute <<-SQL
        UPDATE developer_keys SET user_id_int = CAST(user_id AS UNSIGNED) WHERE user_id IS NOT NULL
      SQL
    end
    remove_column :developer_keys, :user_id
    rename_column :developer_keys, :user_id_int, :user_id
    
    add_column :developer_keys, :name, :string
  end

  def self.down
    drop_table :access_tokens
    change_column :developer_keys, :user_id, :string
    remove_column :developer_keys, :name
  end
end

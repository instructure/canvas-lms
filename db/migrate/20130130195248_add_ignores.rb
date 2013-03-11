class AddIgnores < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :ignores do |t|
      t.string :asset_type, :null => false
      t.integer :asset_id, :null => false, :limit => 8
      t.integer :user_id, :null => false, :limit => 8
      t.string :purpose, :null => false
      t.boolean :permanent, :null => false, :default => false
      t.timestamps
    end
    add_index :ignores, [:asset_id, :asset_type, :user_id, :purpose], :unique => true, :name => 'index_ignores_on_asset_and_user_id_and_purpose'
    add_foreign_key :ignores, :users
  end

  def self.down
    drop_table :ignores
  end
end

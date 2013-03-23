class AddProfiles < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :profiles do |t|
      t.integer  :root_account_id, :limit => 8
      t.string   :context_type
      t.integer  :context_id, :limit => 8
      t.string   :title
      t.string   :path
      t.text     :description
      t.text     :data
      t.string   :visibility # public|private
      t.integer  :position
    end
    add_foreign_key :profiles, :accounts, :column => 'root_account_id'
    add_index :profiles, [:root_account_id, :path], :unique => true
    add_index :profiles, [:context_type, :context_id], :unique => true
  end

  def self.down
    drop_table :profiles
  end
end

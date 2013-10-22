class CreateFeatureFlags < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :feature_flags do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.string :feature, null: false
      t.string :state, default: 'allowed', null: false
      t.integer :locking_account_id, limit: 8
      t.timestamps
    end
    add_index :feature_flags, [:context_id, :context_type, :feature], unique: true,
              name: 'index_feature_flags_on_context_and_feature'
  end

  def self.down
    drop_table :feature_flags
  end
end

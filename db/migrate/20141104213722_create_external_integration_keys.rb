class CreateExternalIntegrationKeys < ActiveRecord::Migration
  tag :predeploy

  def change
    create_table :external_integration_keys do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.string :key_value, null: false, length: 255
      t.string :key_type, null: false

      t.timestamps null: true
    end

    add_index :external_integration_keys, [:context_id, :context_type, :key_type], name: 'index_external_integration_keys_unique', unique: true
  end
end

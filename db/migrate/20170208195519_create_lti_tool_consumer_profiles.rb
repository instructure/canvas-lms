class CreateLtiToolConsumerProfiles < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change

    create_table :lti_tool_consumer_profiles do |t|
      t.text :services
      t.text :capabilities
      t.string :uuid, null: false
      t.integer :developer_key_id, limit: 8, null: false
      t.timestamps null: false
    end

    add_index :lti_tool_consumer_profiles, :developer_key_id, unique: true
    add_index :lti_tool_consumer_profiles, :uuid, unique: true

    add_foreign_key :lti_tool_consumer_profiles, :developer_keys

  end
end

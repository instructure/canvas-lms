class AddLtiToolSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :lti_tool_settings do |t|
      t.integer :settable_id, limit: 8, null: false
      t.string :settable_type, null: false
      t.text :custom
    end

    create_table :lti_tool_links do |t|
      t.integer :resource_handler_id, limit: 8, null: false
      t.string :uuid, null: false
    end

    add_index :lti_tool_links, :uuid, unique: true
    add_index :lti_tool_settings, [:settable_id, :settable_type], unique: true
  end

  def self.down
    drop_table :lti_tool_settings
    drop_table :lti_tool_links
  end

end

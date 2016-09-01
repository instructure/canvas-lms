class CreateContextExternalTools < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :context_external_tools do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.string :domain
      t.string :url
      t.string :shared_secret
      t.string :consumer_key
      t.string :name
      t.text :description
      t.text :settings
      t.string :workflow_state
      
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :context_external_tools
  end
end

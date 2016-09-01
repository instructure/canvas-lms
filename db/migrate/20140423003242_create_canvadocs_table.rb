class CreateCanvadocsTable < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :canvadocs do |t|
      t.string :document_id
      t.string :process_state
      t.integer :attachment_id, limit: 8, null: false
      t.timestamps null: true
    end
    add_index :canvadocs, :document_id, :unique => true
    add_index :canvadocs, :attachment_id
    add_index :canvadocs, :process_state
    add_foreign_key :canvadocs, :attachments
  end

  def self.down
    drop_table :canvadocs
  end
end

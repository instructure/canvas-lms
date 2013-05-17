class AddCrocodoc < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :crocodoc_documents do |t|
      t.string :uuid
      t.string :process_state
      t.integer :attachment_id, :limit => 8
    end
    add_index :crocodoc_documents, :uuid
    add_index :crocodoc_documents, :attachment_id
    add_index :crocodoc_documents, :process_state
  end

  def self.down
    drop_table :crocodoc_documents
  end
end

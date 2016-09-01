class AddTimestampsToCrocodocDocuments < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_timestamps(:crocodoc_documents, null: true)
  end

  def self.down
    remove_column :crocodoc_documents, :created_at
    remove_column :crocodoc_documents, :updated_at
  end
end

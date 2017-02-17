class CreateCanvadocsSubmissionsTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :canvadocs_submissions do |t|
      t.integer :canvadoc_id, limit: 8
      t.integer :crocodoc_document_id, limit: 8
      t.integer :submission_id, limit: 8, null: false
    end

    add_foreign_key :canvadocs_submissions, :submissions
    add_foreign_key :canvadocs_submissions, :canvadocs
    add_foreign_key :canvadocs_submissions, :crocodoc_documents

    add_index :canvadocs_submissions, :canvadoc_id, where: "canvadoc_id IS NOT NULL"
    add_index :canvadocs_submissions, :crocodoc_document_id, where: "crocodoc_document_id IS NOT NULL"
    add_index :canvadocs_submissions, :submission_id
  end
end

class AddCanvadocsSubmissionsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :canvadocs_submissions, :crocodoc_document_id,
              where: "crocodoc_document_id IS NOT NULL",
              algorithm: :concurrently
  end
end

class EnsureUniquenessOnCanvadocsSubmissions < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::RemoveDuplicateCanvadocsSubmissions.run

    remove_index :canvadocs_submissions, :canvadoc_id
    remove_index :canvadocs_submissions, :crocodoc_document_id

    add_index :canvadocs_submissions, [:submission_id, :canvadoc_id],
      where: "canvadoc_id IS NOT NULL",
      name: "unique_submissions_and_canvadocs",
      unique: true, algorithm: :concurrently
    add_index :canvadocs_submissions, [:submission_id, :crocodoc_document_id],
      where: "crocodoc_document_id IS NOT NULL",
      name: "unique_submissions_and_crocodocs",
      unique: true, algorithm: :concurrently
  end

  def down
    remove_index "canvadocs_submissions", name: "unique_submissions_and_canvadocs"
    remove_index "canvadocs_submissions", name: "unique_submissions_and_crocodocs"

    add_index :canvadocs_submissions, :canvadoc_id,
      where: "canvadoc_id IS NOT NULL"
    add_index :canvadocs_submissions, :crocodoc_document_id,
      where: "crocodoc_document_id IS NOT NULL"
  end
end

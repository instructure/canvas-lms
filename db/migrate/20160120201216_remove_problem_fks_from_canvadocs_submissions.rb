class RemoveProblemFksFromCanvadocsSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    remove_foreign_key :canvadocs_submissions, :canvadoc
    remove_foreign_key :canvadocs_submissions, :crocodoc_document
  end
end

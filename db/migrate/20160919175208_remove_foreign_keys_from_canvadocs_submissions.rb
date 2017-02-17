class RemoveForeignKeysFromCanvadocsSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    remove_foreign_key :canvadocs_submissions, :submissions
  end
end

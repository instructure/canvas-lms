class RemoveForeignKeysFromCanvadocsSubmissions < ActiveRecord::Migration
  tag :predeploy

  def change
    remove_foreign_key :canvadocs_submissions, :submissions
  end
end

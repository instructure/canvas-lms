class AddCanvadocIdIndexToCanvadocsSubmissions < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :canvadocs_submissions, :canvadoc_id, :algorithm => :concurrently
  end
end

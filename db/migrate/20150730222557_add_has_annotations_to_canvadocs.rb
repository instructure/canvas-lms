class AddHasAnnotationsToCanvadocs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :canvadocs, :has_annotations, :bool
  end
end

class AddHasAnnotationsToCanvadocs < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :canvadocs, :has_annotations, :bool
  end
end

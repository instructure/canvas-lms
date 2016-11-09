class AddPathToRetainedData < ActiveRecord::Migration
  tag :postdeploy
  def change
    add_column :retained_data, :path, :string
  end
end

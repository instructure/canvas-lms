class AddHiddenToFavorites < ActiveRecord::Migration
  tag :predeploy
  
  def change
    add_column :favorites, :hidden, :boolean
  end
end

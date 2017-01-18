class AddExcusedToSubmissions < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :submissions, :excused, :boolean
  end
end

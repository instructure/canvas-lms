class AddExcusedToSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :submissions, :excused, :boolean
  end
end

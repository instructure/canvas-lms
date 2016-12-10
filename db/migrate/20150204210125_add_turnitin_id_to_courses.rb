class AddTurnitinIdToCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :courses, :turnitin_id, :integer, :limit => 8, unique: true
  end
end

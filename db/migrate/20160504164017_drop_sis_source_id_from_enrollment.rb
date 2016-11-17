class DropSisSourceIdFromEnrollment < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    remove_column :enrollments, :sis_source_id, :string
  end
end

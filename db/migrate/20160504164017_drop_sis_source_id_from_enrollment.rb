class DropSisSourceIdFromEnrollment < ActiveRecord::Migration
  tag :postdeploy

  def change
    remove_column :enrollments, :sis_source_id, :string
  end
end

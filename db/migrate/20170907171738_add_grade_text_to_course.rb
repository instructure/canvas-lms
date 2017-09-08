class AddGradeTextToCourse < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :courses, :gradebook_text, :text
  end
end

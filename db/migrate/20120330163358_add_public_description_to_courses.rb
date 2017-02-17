class AddPublicDescriptionToCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :courses, :public_description, :text
  end

  def self.down
    remove_column :courses, :public_description
  end
end

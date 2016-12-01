class AddDynamicSyllabusInfoToCourses < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :courses, :intro_title, :string
    add_column :courses, :intro_text, :text
  end
end

class AddParametersToCourseImports < ActiveRecord::Migration
  def self.up
    add_column :course_imports, :parameters, :text
  end

  def self.down
    remove_column :course_imports, :parameters
  end
end

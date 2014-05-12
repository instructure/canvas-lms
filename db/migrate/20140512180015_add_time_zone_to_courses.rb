class AddTimeZoneToCourses < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :courses, :time_zone, :string
  end

  def self.down
    remove_column :courses, :time_zone
  end
end

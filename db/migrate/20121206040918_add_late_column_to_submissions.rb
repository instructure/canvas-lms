class AddLateColumnToSubmissions < ActiveRecord::Migration
  tag :predeploy
  
  def self.up
    add_column :submissions, :late, :boolean
  end

  def self.down
    remove_column :submissions, :late
  end
end

class DropSubmissionLateColumn < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :submissions, :late
  end

  def self.down
    add_column :submissions, :late, :boolean
  end
end

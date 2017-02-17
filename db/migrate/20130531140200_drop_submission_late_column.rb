class DropSubmissionLateColumn < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :submissions, :late
  end

  def self.down
    add_column :submissions, :late, :boolean
  end
end

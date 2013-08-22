class DropEnrollmentsIndexOnIdAndType < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_index :enrollments, [:id, :type]
  end

  def self.down
    add_index :enrollments, [:id, :type]
  end
end

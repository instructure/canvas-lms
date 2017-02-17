class DropEnrollmentsIndexOnIdAndType < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_index :enrollments, [:id, :type]
  end

  def self.down
    add_index :enrollments, [:id, :type]
  end
end

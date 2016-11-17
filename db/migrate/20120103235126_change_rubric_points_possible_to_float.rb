class ChangeRubricPointsPossibleToFloat < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :rubrics, :points_possible, :float
  end

  def self.down
    change_column :rubrics, :points_possible, :integer
  end
end

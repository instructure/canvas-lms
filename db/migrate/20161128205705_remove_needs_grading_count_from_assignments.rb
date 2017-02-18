class RemoveNeedsGradingCountFromAssignments < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :assignments, :needs_grading_count
  end

  def down
    add_column :assignments, :needs_grading_count, :integer
    change_column_default :assignments, :needs_grading_count, 0
  end
end

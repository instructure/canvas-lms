class AddResultsToProgresses < ActiveRecord::Migration
  tag :predeploy

  def up
    add_column :progresses, :results, :text
  end

  def down
    remove_column :progresses, :results
  end
end

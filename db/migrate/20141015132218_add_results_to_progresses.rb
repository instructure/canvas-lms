class AddResultsToProgresses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :progresses, :results, :text
  end

  def down
    remove_column :progresses, :results
  end
end

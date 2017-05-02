class AddLateColumnsToSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :submissions, :late_policy_status, :string, limit: 16
    add_column :submissions, :accepted_at, :timestamp
    add_column :submissions, :points_deducted, :decimal, precision: 6, scale: 2
  end

  def down
    remove_column :submissions, :points_deducted
    remove_column :submissions, :accepted_at
    remove_column :submissions, :late_policy_status
  end
end

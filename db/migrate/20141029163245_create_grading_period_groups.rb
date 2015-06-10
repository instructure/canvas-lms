class CreateGradingPeriodGroups < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :grading_period_groups do |t|
      t.integer :course_id, :limit => 8
      t.integer :account_id, :limit => 8
      t.timestamps
    end

    add_foreign_key :grading_period_groups, :courses
    add_foreign_key :grading_period_groups, :accounts
    add_index :grading_period_groups, :course_id
    add_index :grading_period_groups, :account_id
  end

  def self.down
    drop_table :grading_period_groups
  end
end

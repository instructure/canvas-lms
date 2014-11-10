class CreateGradingPeriods < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :grading_periods do |t|
      t.integer :course_id, :limit => 8
      t.integer :account_id, :limit => 8
      t.float :weight, :null => false
      t.datetime :start_date, :null => false
      t.datetime :end_date, :null => false
      t.timestamps
    end

    add_index :grading_periods, :course_id
    add_index :grading_periods, :account_id
  end

  def self.down
    drop_table :grading_periods
  end
end

class AddReportTypeToQuizStatistics < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :quiz_statistics, :report_type, :string
    add_index :quiz_statistics, [:quiz_id, :report_type]
    remove_index :quiz_statistics, :column => :quiz_id
  end

  def self.down
    add_index :quiz_statistics, :quiz_id
    remove_index :quiz_statistics, :column => [:quiz_id, :report_type]
    remove_column :quiz_statistics, :report_type
  end
end

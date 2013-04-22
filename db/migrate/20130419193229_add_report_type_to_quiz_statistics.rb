class AddReportTypeToQuizStatistics < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :quiz_statistics, :report_type, :string
    remove_index :quiz_statistics, :column => :quiz_id
    add_index :quiz_statistics, [:quiz_id, :report_type]
  end

  def self.down
    remove_index :quiz_statistics, :column => [:quiz_id, :report_type]
    remove_column :quiz_statistics, :report_type
    add_index :quiz_statistics, :quiz_id
  end
end

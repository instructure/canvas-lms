class CreateQuizRegradeRuns < ActiveRecord::Migration
  tag :predeploy
  def self.up
    create_table :quiz_regrade_runs do |t|
      t.integer :quiz_regrade_id, limit: 8, null: false
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :quiz_regrade_runs
  end
end

class CreateScoresTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :scores do |t|
      t.integer :enrollment_id, limit: 8, null: false
      t.integer :grading_period_id, limit: 8
      t.string  :workflow_state, default: :active, null: false, limit: 255
      t.float   :current_score
      t.float   :final_score
      t.timestamps
    end

    add_foreign_key :scores, :enrollments
    add_foreign_key :scores, :grading_periods

    add_index :scores, [:enrollment_id, :grading_period_id], unique: true
  end

  def down
    drop_table :scores
  end
end

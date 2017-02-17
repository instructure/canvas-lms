class CreateLiveAssessments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :live_assessments_assessments do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.timestamps null: true
    end
    add_index :live_assessments_assessments, [:context_id, :context_type, :key], unique: true, name: 'index_live_assessments'

    create_table :live_assessments_submissions do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :assessment_id, limit: 8, null: false
      t.float :possible
      t.float :score
      t.datetime :assessed_at
      t.timestamps null: true
    end
    add_index :live_assessments_submissions, [:assessment_id, :user_id], unique: true

    create_table :live_assessments_results do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :assessor_id, limit: 8, null: false
      t.integer :assessment_id, limit: 8, null: false
      t.boolean :passed, null: false
      t.datetime :assessed_at, null: false
    end
    add_index :live_assessments_results, [:assessment_id, :user_id]

    add_foreign_key :live_assessments_submissions, :live_assessments_assessments, column: :assessment_id
    add_foreign_key :live_assessments_submissions, :users
    add_foreign_key :live_assessments_results, :users, column: :assessor_id
    add_foreign_key :live_assessments_results, :live_assessments_assessments, column: :assessment_id
  end

  def self.down
    drop_table :live_assessments_results
    drop_table :live_assessments_submissions
    drop_table :live_assessments_assessments
  end
end

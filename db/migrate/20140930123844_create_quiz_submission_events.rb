class CreateQuizSubmissionEvents < ActiveRecord::Migration
  tag :predeploy

  def up
    create_table :quiz_submission_events do |t|
      t.integer :attempt
      t.string :event_type
      t.integer :quiz_submission_id, limit: 8, null: false
      t.text :answers
      t.datetime :created_at
    end

    # for sorting:
    add_index :quiz_submission_events, :created_at

    # for locating predecessor events:
    add_index :quiz_submission_events, [ :quiz_submission_id, :attempt, :created_at ],
      name: 'event_predecessor_locator_index'

    add_foreign_key :quiz_submission_events, :quiz_submissions
  end

  def down
    drop_table :quiz_submission_events
  end
end

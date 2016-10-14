class CreatePollSessionsAndModifyPolls < ActiveRecord::Migration
  tag :predeploy

  # rubocop:disable Migration/RemoveColumn
  def self.up
    create_table :polling_poll_sessions do |t|
      t.boolean :is_published, null: false, default: false
      t.boolean :has_public_results, null: false, default: false

      t.integer :course_id, limit: 8, null: false
      t.integer :course_section_id, limit: 8
      t.integer :poll_id, limit: 8, null: false

      t.timestamps null: true
    end
    add_column :polling_poll_submissions, :poll_session_id, :integer, limit: 8

    # Polls will be scoped to user as opposed to course.
    # PollSessions scope to course/course_section
    remove_foreign_key :polling_polls, :courses
    remove_column :polling_polls, :course_id
    add_column :polling_polls, :user_id, :integer, limit: 8

    # Get around NOT NULL with no default value constraints
    change_column_null :polling_poll_submissions, :poll_session_id, false
    change_column_null :polling_polls, :user_id, false

    # Requested changes from mobile
    change_column :polling_poll_choices, :is_correct, :boolean, default: false
    rename_column :polling_polls, :title, :question

    remove_index :polling_poll_submissions, [:poll_id, :user_id]

    add_index :polling_poll_sessions, :course_id
    add_index :polling_poll_sessions, :course_section_id
    add_index :polling_poll_sessions, :poll_id
    add_index :polling_poll_submissions, :poll_session_id
    add_index :polling_polls, :user_id

    add_foreign_key :polling_poll_sessions, :courses
    add_foreign_key :polling_poll_sessions, :course_sections
    add_foreign_key :polling_poll_sessions, :polling_polls, column: :poll_id
    add_foreign_key :polling_poll_submissions, :polling_poll_sessions, column: :poll_session_id
    add_foreign_key :polling_polls, :users
  end

  def self.down
    rename_column :polling_polls, :question, :title

    remove_column :polling_polls, :user_id
    add_column :polling_polls, :course_id, :integer, limit: 8, null: false
    add_foreign_key :polling_polls, :courses

    remove_column :polling_poll_submissions, :poll_session_id
    drop_table :polling_poll_sessions
  end
end

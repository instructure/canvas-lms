# frozen_string_literal: true

class AddMissingFkIndexes2 < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :assignments, :migrate_from_id, where: 'migrate_from_id IS NOT NULL', algorithm: :concurrently, if_not_exists: true
    add_index :anonymous_or_moderation_events, :quiz_id, where: 'quiz_id IS NOT NULL', algorithm: :concurrently, if_not_exists: true
    add_index :viewed_submission_comments, :submission_comment_id, algorithm: :concurrently, if_not_exists: true
  end
end

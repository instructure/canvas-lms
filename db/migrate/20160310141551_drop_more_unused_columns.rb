class DropMoreUnusedColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :accounts, :require_authorization_code

    remove_column :assessment_question_bank_users, :deleted_at
    remove_column :assessment_question_bank_users, :permissions
    remove_column :assessment_question_bank_users, :workflow_state

    remove_column :assessment_requests, :comments

    remove_column :asset_user_accesses, :summarized_at

    remove_column :assignments, :grading_scheme_id
    remove_column :assignments, :location

    remove_column :content_migrations, :error_count
    remove_column :content_migrations, :error_data

    remove_column :context_modules, :start_at
    remove_column :context_modules, :end_at

    remove_column :courses, :old_account_id
    remove_column :courses, :show_all_discussion_entries

    remove_column :eportfolio_entries, :url

    remove_column :eportfolios, :context_id
    remove_column :eportfolios, :context_type

    remove_column :external_feed_entries, :start_at
    remove_column :external_feed_entries, :end_at

    remove_column :groups, :default_wiki_editing_roles

    remove_column :inbox_items, :sender

    remove_column :learning_outcome_results, :comments

    remove_column :learning_outcome_question_results, :context_code
    remove_column :learning_outcome_question_results, :context_id
    remove_column :learning_outcome_question_results, :context_type

    remove_column :messages, :notification_category

    remove_column :pseudonyms, :login_path_to_ignore

    remove_column :rubric_associations, :description

    remove_column :sis_batches, :errored_attempts

    remove_column :submission_comments, :recipient_id

    remove_column :users, :merge_to
    remove_column :users, :visibility

    remove_column :web_conference_participants, :workflow_state

    remove_column :wiki_pages, :delayed_post_at
    remove_column :wiki_pages, :recent_editors
    remove_column :wiki_pages, :wiki_page_comments_count
  end

  def down
    add_column :accounts, :require_authorization_code, :boolean

    add_column :assessment_question_bank_users, :deleted_at, :timestamp
    add_column :assessment_question_bank_users, :permissions, :string
    add_column :assessment_question_bank_users, :workflow_state, :string

    add_column :assessment_requests, :comments, :text

    add_column :asset_user_accesses, :summarized_at, :timestamp

    add_column :assignments, :grading_scheme_id, :integer, :limit => 8
    add_column :assignments, :location, :string

    add_column :content_migrations, :error_count, :integer
    add_column :content_migrations, :error_data, :text

    add_column :context_modules, :start_at, :timestamp
    add_column :context_modules, :end_at, :timestamp

    add_column :courses, :old_account_id, :integer, :limit => 8
    add_column :courses, :show_all_discussion_entries, :boolean

    add_column :eportfolio_entries, :url, :string

    add_column :eportfolios, :context_id, :integer, :limit => 8
    add_column :eportfolios, :context_type, :string

    add_column :external_feed_entries, :start_at, :timestamp
    add_column :external_feed_entries, :end_at, :timestamp

    add_column :groups, :default_wiki_editing_roles, :string

    add_column :inbox_items, :sender, :boolean

    add_column :learning_outcome_results, :comments, :string

    add_column :learning_outcome_question_results, :context_code, :string
    add_column :learning_outcome_question_results, :context_id, :integer, :limit => 8
    add_column :learning_outcome_question_results, :context_type, :string

    add_column :messages, :notification_category, :string

    add_column :pseudonyms, :login_path_to_ignore, :string

    add_column :rubric_associations, :description, :text

    add_column :sis_batches, :errored_attempts, :integer

    add_column :submission_comments, :recipient_id, :integer, :limit => 8

    add_column :users, :merge_to, :integer
    add_column :users, :visibility, :string

    add_column :web_conference_participants, :workflow_state, :string

    add_column :wiki_pages, :delayed_post_at, :timestamp
    add_column :wiki_pages, :recent_editors, :string
    add_column :wiki_pages, :wiki_page_comments_count, :integer
  end
end

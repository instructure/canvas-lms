class AddSubmissionDateIndex < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, "user_id, GREATEST(submitted_at, created_at)", name: "index_submissions_on_user_and_greatest_dates", algorithm: :concurrently
  end
end

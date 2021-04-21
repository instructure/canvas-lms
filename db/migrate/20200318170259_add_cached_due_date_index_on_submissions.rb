# frozen_string_literal: true

class AddCachedDueDateIndexOnSubmissions < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, [:user_id, :cached_due_date], algorithm: :concurrently
  end
end

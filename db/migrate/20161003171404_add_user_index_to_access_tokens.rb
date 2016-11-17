class AddUserIndexToAccessTokens < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :access_tokens, :user_id, algorithm: :concurrently
  end
end

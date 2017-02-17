class DisallowNullDeveloperKey < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    scope = AccessToken.where(developer_key_id: nil)
    scope.update_all(developer_key_id: DeveloperKey.default) if scope.exists?
    change_column_null :access_tokens, :developer_key_id, false
  end

  def down
    change_column_null :access_tokens, :developer_key_id, true
  end
end

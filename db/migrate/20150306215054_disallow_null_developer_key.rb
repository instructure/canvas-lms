class DisallowNullDeveloperKey < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def up
    # TODO: Do we really want to do this?
    AccessToken.where(developer_key_id: nil).update_all(developer_key_id: DeveloperKey.default)
    change_column_null :access_tokens, :developer_key_id, false
  end

  def down
    change_column_null :access_tokens, :developer_key_id, true
  end
end

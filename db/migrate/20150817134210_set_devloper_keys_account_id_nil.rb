class SetDevloperKeysAccountIdNil < ActiveRecord::Migration
  tag :postdeploy

  def up
    execute <<-SQL
    UPDATE developer_keys SET account_id = NULL WHERE account_id IS NOT NULL
    SQL
  end
end

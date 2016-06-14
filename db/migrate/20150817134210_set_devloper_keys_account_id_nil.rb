class SetDevloperKeysAccountIdNil < ActiveRecord::Migration
  tag :postdeploy

  def up
    DeveloperKey.where("account_id IS NOT NULL").update_all(account_id: nil)
  end
end

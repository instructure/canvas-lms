class GrandfatherCanvasAuthentication < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    AccountAuthorizationConfig::Canvas.reset_column_information
    Account.root_accounts.each do |account|
      if account.settings[:canvas_authentication] != false || !account.authentication_providers.active.exists?
        account.enable_canvas_authentication
      end
    end
  end

  def down
    AccountAuthorizationConfig.where(auth_type: 'canvas').delete_all
  end
end

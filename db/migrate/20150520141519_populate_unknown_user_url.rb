class PopulateUnknownUserUrl < ActiveRecord::Migration
  tag :predeploy

  def up
    AccountAuthorizationConfig.select("*, unknown_user_url AS uuu").find_each do |aac|
      account = aac.account
      if !account.unknown_user_url.present? && aac['uuu'].present?
        account.unknown_user_url = aac['uuu']
        account.save!
      end
    end
  end
end

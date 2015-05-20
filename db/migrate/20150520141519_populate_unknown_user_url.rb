class PopulateUnknownUserUrl < ActiveRecord::Migration
  tag :predeploy

  def up
    AccountAuthorizationConfig.find_each do |aac|
      account = aac.account
      if !account.unknown_user_url.present? && aac.unknown_user_url.present?
        account.unknown_user_url = aac.unknown_user_url
        account.save!
      end
    end
  end
end

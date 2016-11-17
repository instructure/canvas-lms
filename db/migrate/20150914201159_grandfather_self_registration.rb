class GrandfatherSelfRegistration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    Account.root_accounts.active.each do |account|
      next unless account.settings[:self_registration]

      ap = account.authentication_providers.active.where(auth_type: 'canvas').first
      next unless ap

      ap.self_registration = account.settings[:self_registration_type] || 'all'
      ap.save!
    end
  end
end

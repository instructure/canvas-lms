module DataFixup::SisAppUrlAccountSetting

  def self.run
    Account.root_accounts.find_each do |account|
      if account.settings[:sis_app_token].present?
        account.settings[:sis_app_url] = 'https://sisync.instructure.com'
        account.save!
      end
    end
  end
end
module DataFixup::PopulateAccountAuthSettings

  def self.run
    AccountAuthorizationConfig.find_each do |aac|
      account = aac.account
      if !account.login_handle_name.present? && aac.login_handle_name.present?
        account.login_handle_name = aac.login_handle_name
      end

      if !account.change_password_url.present? && aac.change_password_url.present?
        account.change_password_url = aac.change_password_url
      end
      account.save!
    end
  end

end

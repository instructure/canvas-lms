module DataFixup::PopulateAccountAuthSettings

  def self.run
    AccountAuthorizationConfig.select("*, login_handle_name AS lhn, change_password_url AS cpu").find_each do |aac|
      account = aac.account
      if !account.login_handle_name.present? && aac['lhn'].present?
        account.login_handle_name = aac['lhn']
      end

      if !account.change_password_url.present? && aac['cpu'].present?
        account.change_password_url = aac['cpu']
      end
      account.save!
    end
  end

end

class AllowLongCertificateFingerprint < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :account_authorization_configs, :certificate_fingerprint, :text
  end

  def self.down
    change_column :account_authorization_configs, :certificate_fingerprint, :string
  end
end

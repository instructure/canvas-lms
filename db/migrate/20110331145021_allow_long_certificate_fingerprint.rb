class AllowLongCertificateFingerprint < ActiveRecord::Migration
  def self.up
    change_column :account_authorization_configs, :certificate_fingerprint, :text
  end

  def self.down
    change_column :account_authorization_configs, :certificate_fingerprint, :string
  end
end

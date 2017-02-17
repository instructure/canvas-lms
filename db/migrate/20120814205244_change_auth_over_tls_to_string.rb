class ChangeAuthOverTlsToString < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # existing Rails process will continue seeing it as boolean until they restart;
    # this is fine, since they fetch as a string anyway
    change_column :account_authorization_configs, :auth_over_tls, :string
  end

  def self.down
    # technically it is reversible, but requires db specific syntax in postgres
    raise ActiveRecord::IrreversibleMigration
  end
end

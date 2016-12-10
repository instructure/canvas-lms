class PopulateAccountAuthSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    DataFixup::PopulateAccountAuthSettings.run
  end
end

class PopulateAccountAuthSettings < ActiveRecord::Migration
  tag :predeploy

  def up
    DataFixup::PopulateAccountAuthSettings.run
  end
end

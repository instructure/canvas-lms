class LengthenUserServicesToken < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column :user_services, :token, :text
  end

  def down
    change_column :user_services, :token, :string, :limit => 255
  end
end

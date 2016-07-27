class AddTurnitinOriginalityToAccounts < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :accounts, :turnitin_originality, :string
  end
end

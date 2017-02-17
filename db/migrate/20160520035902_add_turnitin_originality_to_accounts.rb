class AddTurnitinOriginalityToAccounts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :accounts, :turnitin_originality, :string
  end
end

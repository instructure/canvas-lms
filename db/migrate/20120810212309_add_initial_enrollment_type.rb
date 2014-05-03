class AddInitialEnrollmentType < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :users, :initial_enrollment_type, :string
  end

  def self.down
    remove_column :users, :initial_enrollment_type
  end
end

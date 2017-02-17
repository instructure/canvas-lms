class GrandfatherOpenRegistration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Account.root_accounts.find_each do |account|
      # Grandfather all old accounts to open_registration
      account.settings = { :open_registration => true }
      # These settings were previously exposed, but defaulted to true. They now default to false.
      # So grandfather in the previous setting, accounting for the old default
      [:teachers_can_create_courses, :students_can_create_courses, :no_enrollments_can_create_courses].each do |setting|
        account.settings = { setting => true } if account.settings[setting] != false
      end
      account.save!
    end
  end

  def self.down
  end
end

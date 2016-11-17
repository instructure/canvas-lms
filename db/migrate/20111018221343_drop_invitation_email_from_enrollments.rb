class DropInvitationEmailFromEnrollments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_column :enrollments, :invitation_email
  end

  def self.down
    add_column :enrollments, :invitation_email, :string
  end
end

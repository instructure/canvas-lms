class DropInvitationEmailFromEnrollments < ActiveRecord::Migration
  def self.up
    remove_column :enrollments, :invitation_email
  end

  def self.down
    add_column :enrollments, :invitation_email, :string
  end
end

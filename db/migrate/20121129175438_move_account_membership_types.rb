class MoveAccountMembershipTypes < ActiveRecord::Migration[4.2]
  # run twice, to pick up any new csv-memberships created
  # after the predeploy migration but before the deploy
  tag :postdeploy

  def self.up
    # for proper security, we need the roles copied to the Roles table
    # before the code that looks for it there is deployed,
    # hence the synchronous predeploy fixup.  there is not a lot of data
    # involved here, so it should not be too painful.
    DataFixup::MoveAccountMembershipTypesToRoles.run
  end

  def self.down
  end
end

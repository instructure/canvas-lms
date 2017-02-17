class GenerateOldAccountOpaqueIDs < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # Set all the root account opaque ids to their old value so that LTI
    # integrations won't break
    DataFixup::SetAccountLtiOpaqueIds.send_later_if_production(:run)
  end
end

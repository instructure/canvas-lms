class GrandfatherDefaultAccountInvitationPreviews < ActiveRecord::Migration
  # yes, predeploy, so that the setting is preserved before the new code goes live
  tag :predeploy

  def self.up
    return unless Shard.current == Account.default.shard
    account = Account.default
    account.settings[:allow_invitation_previews] = true
    account.save!
  end

  def self.down
  end
end

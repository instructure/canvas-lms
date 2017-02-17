class GrandfatherDefaultAccountInvitationPreviews < ActiveRecord::Migration[4.2]
  # yes, predeploy, so that the setting is preserved before the new code goes live
  tag :predeploy

  def self.up
    Account.connection.schema_cache.clear!
    Account.reset_column_information
    return unless Account.default && Shard.current == Account.default.shard
    account = Account.default
    account.settings[:allow_invitation_previews] = true
    account.save!
  end

  def self.down
  end
end

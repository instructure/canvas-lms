class GrandfatherDefaultAccountSelfRegistration < ActiveRecord::Migration
  # yes, predeploy, so that the setting is preserved before the new code goes live
  tag :predeploy

  def self.up
    return unless Account.default && Shard.current == Account.default.shard
    account = Account.default
    if account.no_enrollments_can_create_courses?
      account.settings[:self_registration] = true
      account.save!
    end
  end

  def self.down
  end
end

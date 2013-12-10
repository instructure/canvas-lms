class FixSisCommunicationChannels < ActiveRecord::Migration
  disable_ddl_transaction!

  def self.up
    begin
      pseudonym_ids = Pseudonym.joins(:sis_communication_channel).where("pseudonyms.user_id<>communication_channels.user_id").limit(1000).pluck(:id)
      Pseudonym.where(:id => pseudonym_ids).update_all(:sis_communication_channel_id => nil)
      sleep 1
    end until pseudonym_ids.empty?
  end

  def self.down
  end
end

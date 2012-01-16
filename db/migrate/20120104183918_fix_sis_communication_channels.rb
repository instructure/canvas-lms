class FixSisCommunicationChannels < ActiveRecord::Migration
  def self.up
    if supports_ddl_transactions?
      commit_db_transaction
      decrement_open_transactions while open_transactions > 0
    end

    begin
      pseudonym_ids = Pseudonym.find(:all, :select => 'pseudonyms.id', :joins => :sis_communication_channel, :conditions => "pseudonyms.user_id<>communication_channels.user_id", :limit => 1000).map(&:id)
      Pseudonym.update_all({:sis_communication_channel_id => nil}, :id => pseudonym_ids)
      sleep 1
    end until pseudonym_ids.empty?

    if supports_ddl_transactions?
      increment_open_transactions
      begin_db_transaction
    end
  end

  def self.down
  end
end

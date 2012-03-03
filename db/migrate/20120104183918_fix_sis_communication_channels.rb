class FixSisCommunicationChannels < ActiveRecord::Migration
  self.transactional = false

  def self.up
    begin
      pseudonym_ids = Pseudonym.find(:all, :select => 'pseudonyms.id', :joins => :sis_communication_channel, :conditions => "pseudonyms.user_id<>communication_channels.user_id", :limit => 1000).map(&:id)
      Pseudonym.update_all({:sis_communication_channel_id => nil}, :id => pseudonym_ids)
      sleep 1
    end until pseudonym_ids.empty?
  end

  def self.down
  end
end

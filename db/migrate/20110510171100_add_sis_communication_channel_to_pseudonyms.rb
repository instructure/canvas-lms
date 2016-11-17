class AddSisCommunicationChannelToPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :pseudonyms, :sis_communication_channel_id, :integer, :limit => 8
  end

  def self.down
    remove_column :pseudonyms, :sis_communication_channel_id
  end
end

class AddCommunicationChannelsIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :communication_channels, [:path, :path_type]
      connection.execute("CREATE INDEX index_communication_channels_on_path_and_path_type ON #{CommunicationChannel.quoted_table_name} (LOWER(path), path_type)")
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP INDEX index_communication_channels_on_path_and_path_type")
      add_index :communication_channels, [:path, :path_type]
    end
  end
end

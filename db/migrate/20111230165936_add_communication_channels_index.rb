class AddCommunicationChannelsIndex < ActiveRecord::Migration
  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :communication_channels, [:path, :path_type]
      connection.execute("CREATE INDEX index_communication_channels_on_path_and_path_type ON communication_channels (LOWER(path), path_type)")
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP INDEX index_communication_channels_on_path_and_path_type")
      add_index :communication_channels, [:path, :path_type]
    end
  end
end

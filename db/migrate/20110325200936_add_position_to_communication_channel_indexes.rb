class AddPositionToCommunicationChannelIndexes < ActiveRecord::Migration
  def self.up
    remove_index :communication_channels, :column => %w(user_id)
    add_index    :communication_channels, %w(user_id position)

    remove_index :communication_channels, :column => %w(pseudonym_id)
    add_index    :communication_channels, %w(pseudonym_id position)
  end

  def self.down
    remove_index :communication_channels, :column => %w(user_id position)
    add_index    :communication_channels, %w(user_id)

    remove_index :communication_channels, :column => %w(pseudonym_id position)
    add_index    :communication_channels, %w(pseudonym_id)
  end
end

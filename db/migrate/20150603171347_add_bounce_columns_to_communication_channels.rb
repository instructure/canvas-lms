class AddBounceColumnsToCommunicationChannels < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :communication_channels, :last_bounce_at, :datetime
    add_column :communication_channels, :last_bounce_details, :text, length: 32768
    add_column :communication_channels, :last_suppression_bounce_at, :datetime
  end
end

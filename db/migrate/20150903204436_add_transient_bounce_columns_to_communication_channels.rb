class AddTransientBounceColumnsToCommunicationChannels < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :communication_channels, :last_transient_bounce_at, :datetime
    add_column :communication_channels, :last_transient_bounce_details, :text, length: 32768
  end
end

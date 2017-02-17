class AddRecordingReadyToWebConference < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :web_conferences, :recording_ready, :boolean
  end
end

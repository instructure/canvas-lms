class AddRecordingReadyToWebConference < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :web_conferences, :recording_ready, :boolean
  end
end

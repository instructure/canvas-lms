class FixProfilePicturesRedux < ActiveRecord::Migration
  tag :postdeploy

  def self.up
  DataFixup::RegenerateUserThumbnails.send_later_if_production(:run)
  end

  def self.down
  end
end
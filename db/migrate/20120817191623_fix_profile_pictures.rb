class FixProfilePictures < ActiveRecord::Migration
  tag :postdeploy

  class User < ActiveRecord::Base
    attr_accessible :id
  end

  def self.up
    # we don't support twitter or linked in profile pictures anymore, because
    # they are too small
    ids = User.where(:avatar_image_source => %w(twitter linkedin)).map(&:id)
    now = Time.now
    User.update_all(
      {
        :avatar_image_source => 'no_pic',
        :avatar_image_url => nil,
        :avatar_image_updated_at => now
      },
      :id => ids)

    DataFixup::RegenerateUserThumbnails.send_later_if_production(:run)
  end

  def self.down
  end
end

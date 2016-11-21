class FixProfilePictures < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # we don't support twitter or linked in profile pictures anymore, because
    # they are too small
    User.where(:avatar_image_source => ['twitter', 'linkedin']).
        update_all(
          :avatar_image_source => 'no_pic',
          :avatar_image_url => nil,
          :avatar_image_updated_at => Time.now.utc
        )

    DataFixup::RegenerateUserThumbnails.send_later_if_production(:run)
  end

  def self.down
  end
end

module DataFixup::RegenerateUserThumbnails
  def self.run
    User.find_in_batches(:include => :active_images) do |users|
      attachments = users.map(&:active_images).flatten
      attachments.each do |a|
        a.thumbnails.destroy_all
        tmp_file = a.create_temp_file
        a.create_or_update_thumbnail(tmp_file, :thumb, '128x128')
        a.save
      end
    end
  end
end

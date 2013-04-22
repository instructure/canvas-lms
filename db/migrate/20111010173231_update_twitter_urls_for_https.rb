class UpdateTwitterUrlsForHttps < ActiveRecord::Migration
  def self.up
    while true
      users = User.where("avatar_image_source='twitter' AND avatar_image_url NOT LIKE 'https%'").limit(500).each do |u|
        u.avatar_image = { 'type' => 'twitter'  }
        u.save!
      end
      break if users.empty?
    end
  end

  def self.down
  end
end

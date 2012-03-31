class Cacher < ActiveRecord::Observer
  observe :user

  def self.avatar_cache_key(user_id, account_avatar_setting)
    ['avatar_img', user_id, account_avatar_setting].cache_key
  end

  def after_update(obj)
    case obj
    when User
      if obj.avatar_image_url_changed? ||
         obj.avatar_image_source_changed? ||
         obj.avatar_state_changed?
        User::AVATAR_SETTINGS.each do |avatar_setting|
          Rails.cache.delete(Cacher.avatar_cache_key(obj.id, avatar_setting))
        end
      end
    end
  end
end

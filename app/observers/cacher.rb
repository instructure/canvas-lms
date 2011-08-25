class Cacher < ActiveRecord::Observer
  observe :user

  def self.avatar_cache_key(user_id)
    ['avatar_img', user_id].cache_key
  end

  def after_update(obj)
    case obj
    when User
      if obj.avatar_image_url_changed? ||
         obj.avatar_image_source_changed? ||
         obj.avatar_state_changed?
        Rails.cache.delete(Cacher.avatar_cache_key(obj.id))
      end
    end
  end
end

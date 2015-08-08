class Cacher < ActiveRecord::Observer
  observe :user, :account_user

  def self.avatar_cache_key(user_id, account_avatar_setting)
    ['avatar_img', user_id, account_avatar_setting].cache_key
  end

  def self.inline_avatar_cache_key(user_id, account_avatar_setting)
    ['inline_avatar_img', user_id, account_avatar_setting].cache_key
  end

  def after_update(obj)
    case obj
    when User
      if obj.avatar_image_url_changed? ||
         obj.avatar_image_source_changed? ||
         obj.avatar_state_changed?
        User::AVATAR_SETTINGS.each do |avatar_setting|
          Rails.cache.delete(Cacher.avatar_cache_key(obj.id, avatar_setting))
          Rails.cache.delete(Cacher.inline_avatar_cache_key(obj.id, avatar_setting))
        end
      end
    end
  end

  def after_save(obj)
    case obj
    when AccountUser
      if obj.account_id == Account.site_admin.id
        Switchman::DatabaseServer.send_in_each_region(self.class,
                                                      :clear_all_site_admin_account_users,
                                                      singleton: "clear_all_site_admin_account_users")
      end
    end
  end

  def self.clear_all_site_admin_account_users
    MultiCache.delete("all_site_admin_account_users3")
  end

  def after_destroy(obj)
    after_save(obj)
  end
end

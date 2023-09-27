# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Setting < Switchman::UnshardedRecord
  def self.get(name, default, expires_in: nil, set_if_nx: false, skip_cache: false)
    raise ArgumentError, "Cannot specify both `expires_in` and `skip_cache`" if expires_in && skip_cache

    cache.fetch(name, expires_in:) do
      fetch = proc { Setting.pluck(:name, :value).to_h }
      all_settings = if skip_cache
                       # we want to skip talking to redis, but it's okay to use the in-proc cache
                       @all_settings ||= fetch.call
                     elsif expires_in
                       # ignore the in-proc cache, but check redis; it will have been properly
                       # cleared by whoever set it, they just have no way to clear the in-proc cache
                       @all_settings = MultiCache.fetch("all_settings", &fetch)
                     else
                       # use both caches
                       @all_settings ||= MultiCache.fetch("all_settings", &fetch)
                     end

      if all_settings.key?(name)
        all_settings[name]&.to_s
      else
        Setting.set(name, default) if set_if_nx
        default&.to_s
      end
    end
  rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
    # the db may not exist yet
    Rails.logger&.warn("Unable to read setting: #{e}")
    default&.to_s
  end

  # Note that after calling this, you should send SIGHUP to all running Canvas processes
  def self.set(name, value, secret: nil)
    s = Setting.where(name:).first_or_initialize
    s.value = value&.to_s
    s.secret = secret unless secret.nil?
    s.save!
    cache.delete(name)
    @all_settings = nil
    MultiCache.delete("all_settings")

    if Rails.const_defined? :Console
      message = Setting.get("setting_set_sighup_required_message", "** NOTE: After calling `Setting.set`, SIGHUP must be sent to all Canvas processes **")
      Rails.logger.info(message)
    end
  end

  # this cache doesn't get invalidated by other rails processes, obviously, so
  # use this only for relatively unchanging data
  def self.cache
    @cache ||= ActiveSupport::Cache.lookup_store(:memory_store, namespace: -> {})
  end

  def self.reset_cache!
    @all_settings = nil
    cache.clear
  end

  def self.remove(name)
    cache.delete(name)
    Setting.where(name:).delete_all
    @all_settings = nil
    MultiCache.delete("all_settings")
  end

  Canvas::Reloader.on_reload { reset_cache! }
end

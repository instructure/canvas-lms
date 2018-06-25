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

class Setting < ActiveRecord::Base
  SITE_ADMIN_ACCESS_TO_NEW_DEV_KEY_FEATURES = 'site_admin_access_to_new_dev_key_features'.freeze

  self.shard_category = :unsharded if self.respond_to?(:shard_category=)

  def self.get(name, default, cache_options: nil)
    begin
      cache.fetch(name, cache_options) do
        Setting.where(name: name).first&.value || default&.to_s
      end
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
      # the db may not exist yet
      Rails.logger.warn("Unable to read setting: #{e}") if Rails.logger
      default&.to_s
    end
  end

  # Note that after calling this, you should send SIGHUP to all running Canvas processes
  def self.set(name, value)
    cache.delete(name)
    s = Setting.where(name: name).first_or_initialize
    s.value = value.try(:to_s)
    s.save!
  end

  def self.get_or_set(name, new_val)
    Setting.where(name: name).first_or_create(value: new_val).value
  end

  # this cache doesn't get invalidated by other rails processes, obviously, so
  # use this only for relatively unchanging data
  def self.cache
    @cache ||= ActiveSupport::Cache.lookup_store(:memory_store)
  end

  def self.reset_cache!
    cache.clear
  end

  def self.remove(name)
    cache.delete(name)
    Setting.where(name: name).delete_all
  end
end

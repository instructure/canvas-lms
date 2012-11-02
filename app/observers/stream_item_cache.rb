#
# Copyright (C) 2012 Instructure, Inc.
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

class StreamItemCache < ActiveRecord::Observer
  observe :stream_item_instance

  def after_save(model)
    invalidate_recent_stream_items model
  end

  def invalidate_recent_stream_items(stream_instance)
    dashboard_key = StreamItemCache.recent_stream_items_key(stream_instance.user)
    context_key   = StreamItemCache.recent_stream_items_key(stream_instance.user, stream_instance.context_code)
    Rails.cache.delete dashboard_key
    Rails.cache.delete context_key
  end

  def self.invalidate_context_stream_item_key(context_code)
    Rails.cache.delete ["context_stream_item_key", context_code].cache_key
  end

  # Generate a cache key for User#recent_stream_items
  def self.recent_stream_items_key(user, context_code = nil)
    ['recent_stream_items', user.id, context_stream_item_key(context_code)].cache_key
  end

  # Returns a cached cache key for the context_code with the time so all
  # stream item cache keys for a context can later be invalidated.
  def self.context_stream_item_key(context_code)
    return unless context_code
    Rails.cache.fetch(["context_stream_item_key", context_code].cache_key) do
      "#{context_code}-#{Time.now.to_i}"
    end
  end

end

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

class MultiCache
  class << self
    delegate :fetch, :delete, to: :cache

    def cache
      unless defined?(@multi_cache)
        ha_cache_config = YAML.load(Canvas::DynamicSettings.find(tree: :private, cluster: Canvas.cluster)["ha_cache.yml"] || "{}").symbolize_keys || {}
        if (ha_cache_config[:cache_store])
          ha_cache_config[:url] = ha_cache_config[:servers] if ha_cache_config[:servers]
          store = ActiveSupport::Cache.lookup_store(ha_cache_config[:cache_store].to_sym, ha_cache_config)
          store.options.delete(:namespace)
          @multi_cache = store
        end
      end
      @multi_cache || Rails.cache
    end

    def reset
      remove_instance_variable(:@multi_cache) if instance_variable_defined?(:@multi_cache)
    end
  end

  Canvas::Reloader.on_reload { reset }
end

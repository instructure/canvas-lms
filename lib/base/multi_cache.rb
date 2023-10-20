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

class MultiCache
  class << self
    delegate :fetch, :delete, :validate_consul_event, to: :cache

    def cache
      unless defined?(@cache)
        ha_cache_config = YAML.safe_load(DynamicSettings.find(tree: :private, cluster: Canvas.cluster)["ha_cache.yml", failsafe_cache: Rails.root.join("config")] || "{}").symbolize_keys || {}
        @cache = if ha_cache_config[:cache_store]
                   ActiveSupport::Cache.lookup_store(ha_cache_config.delete(:cache_store).to_sym, ha_cache_config.to_h.deep_symbolize_keys)
                 else
                   config = Canvas.cache_store_config_for(Rails.env).dup || {}
                   # MultiCache has to have an expiration
                   config[:expires_in] ||= 300
                   Canvas.lookup_cache_store(config, Rails.env)
                 end
        @cache.options.delete(:namespace) # remove the namespace that switchman added; MultiCache is global
      end
      @cache
    end

    def reset
      remove_instance_variable(:@cache) if instance_variable_defined?(:@cache)
    end
  end

  Canvas::Reloader.on_reload { reset }
end

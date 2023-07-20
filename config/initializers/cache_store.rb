# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

last_cache_config = {}
cached_cache_config = Rails.root.join("config/cache_store.yml.cached")

load_cache_config = lambda do
  raw_config = {}
  first_try = true

  begin
    cache_map = {}

    searched = Set.new
    clusters_to_search = Switchman::DatabaseServer.all.map(&:id)
    until clusters_to_search.empty?
      cluster = clusters_to_search.shift
      next if searched.include?(cluster)

      searched << cluster
      config = if first_try
                 raw_config[cluster] = Canvas.cache_store_config_for(cluster)
               else
                 raw_config[cluster]
               end

      # link to another cluster
      if config.is_a?(String)
        clusters_to_search << config
        cache_map[cluster] = config
        next
      end

      unless config.present?
        cache_map.delete(cluster)
        next
      end

      last_cluster_cache_config = last_cache_config[cluster]
      last_cache_config[cluster] = config

      cache_map[cluster] = if last_cluster_cache_config == config
                             Switchman.config[:cache_map][cluster]
                           else
                             Canvas.lookup_cache_store(config, cluster)
                           end
    end

    cached_raw_config = cached_cache_config.read if cached_cache_config.exist?
    yaml_raw_config = YAML.dump(raw_config)
    begin
      cached_cache_config.write(yaml_raw_config) if cached_raw_config != yaml_raw_config
    rescue Errno::EACCES
      # ignore permission errors
    end

    # resolve links
    cache_map.each_key do |cluster_name|
      value = cluster_name
      while value.is_a?(String)
        value = cache_map[value]
      end
      cache_map[cluster_name] = value
    end

    # fallback for no configuration whatsoever
    cache_map[Rails.env] ||= ActiveSupport::Cache.lookup_store(:null_store)

    Switchman::DatabaseServer.all.each do |db|
      db.instance_variable_set(:@cache_store, nil)
    end

    Switchman.config[:cache_map] = cache_map
  rescue Diplomat::KeyNotFound, Diplomat::UnknownStatus, Diplomat::PathNotFound => e
    if first_try && cached_cache_config.exist?
      warn "Failed to connect to Consul to read cache store config: #{e}"
      # if we can't find consul, fall back to the cached config
      raw_config = YAML.safe_load_file(cached_cache_config)
      first_try = false
      retry
    end
    raise
  end
end
load_cache_config.call
Canvas::Reloader.on_reload(&load_cache_config)

ActiveSupport::Notifications.subscribe("cache_generate.active_support") do |_name, start, finish, _id, _options|
  elapsed_time = finish - start
  # used by Redis::Client#log_request_response added in lib/canvas/redis.rb
  Thread.current[:last_cache_generate] = elapsed_time
end

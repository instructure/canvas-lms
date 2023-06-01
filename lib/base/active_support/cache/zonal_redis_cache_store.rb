# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

Bundler.require "redis"

class ActiveSupport::Cache::ZonalRedisCacheStore < ActiveSupport::Cache::Store
  def initialize(zones: {},
                 **additional_options)
    super(**additional_options.slice(:namespace, :compress, :compress_threshold, :expires_in, :race_condition_ttl, :coder))

    all_urls = zones.values.flatten.sort
    @redis = ActiveSupport::Cache.lookup_store(:redis_cache_store, { url: all_urls }.merge(additional_options))
    @caches = {}
    zones.each do |zone, url|
      @caches[zone] = ActiveSupport::Cache.lookup_store(:redis_cache_store, { url: }.merge(additional_options))
    end
  end

  delegate :read_multi, :read_entry, to: :zonal_store

  # This redis is for use by Canvas.redis for things that must be shared in a single place between AZs
  attr_reader :redis

  def inspect
    "#<#{self.class} #{@caches.map { |k, v| "#{k}=#{v.inspect}" }.join(" ")}>"
  end

  def info
    @caches.transform_values(&:info)
  end

  def delete_matched(matcher, options = nil)
    @caches.each_value { |c| c.delete_matched(matcher, options) }
  end

  def clear(**options)
    @caches.each_value { |c| c.clear(**options) }
  end

  def read_multi(*names)
    zonal_store.read_multi(*names)
  end

  protected

  def read_entry(key, **options)
    zonal_store.send(:read_entry, key, **options)
  end

  def zonal_store
    @zonal_store ||= @caches[Canvas.availability_zone || @caches.keys.first]
  end

  def write_entry(key, entry, raw: false, **options)
    @caches.each_value { |c| c.send(:write_entry, key, entry, raw:, **options) }
  end

  def delete_entry(key, **options)
    @caches.each_value { |c| c.send(:delete_entry, key, **options) }
  end
end

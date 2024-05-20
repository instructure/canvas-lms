# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class ActiveSupport::Cache::HaStore < ActiveSupport::Cache::RedisCacheStore
  include ActiveSupport::Cache::SafeRedisRaceCondition

  def initialize(consul_datacenters: nil,
                 consul_event: nil,
                 lock_timeout: 5,
                 **kwargs)
    super(**kwargs)
    options[:lock_timeout] = lock_timeout
    options[:consul_datacenters] = consul_datacenters
    options[:consul_event] = consul_event
  end

  def delete_matched(matcher, options = nil)
    # do it locally
    super

    options = merged_options(options)
    # then if so configured, trigger consul
    if options[:consul_event]
      pattern = namespace_key(matcher, options)
      datacenters = Array.wrap(options[:consul_datacenters]).presence || [nil]
      datacenters.each do |dc|
        # Diplomat is silly and doesn't use kwargs for some reason
        Diplomat::Event.fire(options[:consul_event], "DELETE_MATCHED|#{pattern}", nil, nil, nil, dc)
      end
    end
  end

  def clear
    # do it locally
    super
    # then if so configured, trigger consul
    if options[:consul_event]
      datacenters = Array.wrap(options[:consul_datacenters]).presence || [nil]
      datacenters.each do |dc|
        # Diplomat is silly and doesn't use kwargs for some reason
        Diplomat::Event.fire(options[:consul_event], "FLUSHDB", nil, nil, nil, dc)
      end
    end
  end

  def validate_consul_event
    key = SecureRandom.uuid
    patience = 15
    write(key, 1, expires_in: patience * 2)
    delete(key, skip_local: true)
    # yes, really, a sleep. we need to run on the same node because we only wrote
    # to this node. which is why we skip_local'ed above, to ensure the delete
    # actually went through the consul event stream
    sleep patience
    if read(key).nil?
      InstStatsd::Statsd.gauge("ha_store_event_validate_consul_event", 1)
      true
    else
      InstStatsd::Statsd.gauge("ha_store_event_validate_consul_event", 0)
      false
    end
  end

  protected

  def delete_entry(key, **options)
    # do it locally
    result = super unless options[:skip_local]
    # then if so configured, trigger consul
    if options[:consul_event]
      datacenters = Array.wrap(options[:consul_datacenters]).presence || [nil]
      datacenters.each do |dc|
        # TODO: after the new version of consume_consul_events is deployed everywhere, replace key with "DELETE|#{key}"
        Diplomat::Event.fire(options[:consul_event], key, nil, nil, nil, dc)
      end
      # no idea if we actually cleared anything
      false
    else
      result
    end
  end
end

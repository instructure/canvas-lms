#
# Copyright (C) 2014 Instructure, Inc.
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

# These tweaks allow us to force the Rails cache store to a particular value
# for a period. Only disable_cache{...} should actually be used by non-spec
# code, since forcing a particular non-null cache store at run time will not
# jive with other caching enhancements that may cause multiple differentiated
# cache stores to be in use at the same time.
#
# the force_cache{...} method and its component force_cache! and unforce_cache!
# methods are available, however, for use in specs that need to turn caching on
# for a short time (caching is off by default for specs). any differentiated
# caching should not be in effect during specs.
#
class << Rails
  def forced_cache_stack
    @forced_cache_stack ||= []
  end

  # forces RAILS_CACHE to be the given cache store. if the argument
  # is a config, will instantiate that config into a store
  def force_cache!(new_cache=:memory_store)
    # normalize new_cache into an instantiated cache store
    new_cache ||= :null_store
    if CANVAS_RAILS2 && new_cache == :null_store
      require 'nil_store'
      new_cache = NilStore.new
    end
    new_cache = ActiveSupport::Cache.lookup_store(new_cache)

    # save off old cache state
    forced_cache_stack.push([RAILS_CACHE, ActionController::Base.perform_caching])

    # set new cache state
    if CANVAS_RAILS2
      ActionController::Base.cache_store = new_cache
      silence_warnings { Object.const_set(:RAILS_CACHE, new_cache) }
    else
      Switchman::DatabaseServer.all.each{ |s| s.stubs(:cache_store).returns(new_cache) }
    end
    ActionController::Base.perform_caching = true
  end

  # stops forcing Rails.cache, letting it revert to its previous behavior.
  def unforce_cache!
    # no-op if caching is not currently forced
    return unless cache_forced?

    # pop state to restore from stack
    old_cache, old_perform_caching = forced_cache_stack.pop

    # set back to saved state
    if CANVAS_RAILS2
      ActionController::Base.cache_store = old_cache
      silence_warnings { Object.const_set(:RAILS_CACHE, old_cache) }
    else
      Switchman::DatabaseServer.all.each {|s| s.unstub(:cache_store) }
    end
    ActionController::Base.perform_caching = old_perform_caching
  end

  # as force_cache!, but only for the duration of the given block.
  def force_cache(new_cache=:memory_store)
    force_cache!(new_cache)
    yield
  ensure
    unforce_cache!
  end

  # is Rails.cache currently being forced?
  def cache_forced?
    forced_cache_stack.present?
  end

  # specific case of force_cache! with a :null_store as the forcing target,
  # effectively disabling the cache.
  def disable_cache!
    force_cache!(:null_store)
  end

  # same as disable_cache!, but only for the duration of the given block.
  def disable_cache
    force_cache(:null_store) { yield }
  end
end

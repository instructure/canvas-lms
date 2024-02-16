# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "debug"
require "canvas_cache"
require "action_controller"
require "active_record"

Rails.env = "test"

# give the logger some implementation since
# we aren't initializing a full app in these specs
Rails.logger = Logger.new($stdout)
ActiveSupport::Cache.format_version = 7.0

RSpec.shared_context "caching_helpers", shared_context: :metadata do
  # provide a way to temporarily replace the rails
  # cache with one constructed in a spec.
  def override_cache(new_cache = :memory_store)
    previous_cache = Rails.cache
    previous_perform_caching = ActionController::Base.perform_caching
    set_cache(new_cache)
    if block_given?
      begin
        yield
      ensure
        allow(Rails).to receive(:cache).and_return(previous_cache)
        allow(ActionController::Base).to receive_messages(cache_store: previous_cache, perform_caching: previous_perform_caching)
        allow_any_instance_of(ActionController::Base).to receive(:cache_store).and_return(previous_cache)
        allow_any_instance_of(ActionController::Base).to receive(:perform_caching).and_return(previous_perform_caching)
      end
    end
  end

  def set_cache(new_cache)
    cache_opts = {}
    if new_cache == :redis_cache_store
      if CanvasCache::Redis.enabled?
        cache_opts[:redis] = CanvasCache::Redis.redis
      else
        skip "redis required"
      end
    end
    new_cache ||= :null_store
    new_cache = ActiveSupport::Cache.lookup_store(new_cache, cache_opts)
    allow(Rails).to receive(:cache).and_return(new_cache)
    allow(ActionController::Base).to receive_messages(cache_store: new_cache, perform_caching: true)
    allow_any_instance_of(ActionController::Base).to receive(:cache_store).and_return(new_cache)
    allow_any_instance_of(ActionController::Base).to receive(:perform_caching).and_return(true)
    # TODO: re-enable this once multi_cache is pulled over to gem.
    # MultiCache.reset
  end

  # some specs need to check what's being written to the log, provide
  # an easy way to do so here
  def capture_log_messages
    prev_logger = Rails.logger

    collector_class = Class.new(ActiveSupport::Logger) do
      attr_reader :captured_message_stack

      def initialize
        super(nil)
        @captured_message_stack = []
      end

      def add(_severity, message = nil, progname = nil)
        message = (message || (block_given? && yield) || progname).to_s
        @captured_message_stack << message
      end
    end

    lgr = collector_class.new
    Rails.logger = lgr
    yield
    lgr.captured_message_stack
  ensure
    Rails.logger = prev_logger
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = "random"

  config.before do
    # load config from local spec/fixtures/config/redis.yml
    # so that we have something for ConfigFile to parse.
    target_location = Pathname.new(File.join(File.dirname(__FILE__), "fixtures"))
    allow(Rails).to receive(:root).and_return(target_location)

    # make sure redis is in a stable state before every spec
    CanvasCache::Redis.redis._client.config.circuit_breaker&.instance_variable_set(:@state, :closed)
    CanvasCache::Redis.redis._client.config.circuit_breaker&.instance_variable_get(:@errors)&.clear
    GuardRail.activate(:deploy) { CanvasCache::Redis.redis.flushdb }
  end
end

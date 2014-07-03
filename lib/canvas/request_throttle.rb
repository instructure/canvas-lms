# Copyright (C) 2013 Instructure, Inc.
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
require 'set'

module Canvas
class RequestThrottle
  # this @@last_sample data isn't thread-safe, and if canvas ever becomes
  # multi-threaded, we'll have to just get rid of it since we can't measure
  # per-thread heap used
  @@last_sample = 0

  class ActionControllerLogSubscriber < ActiveSupport::LogSubscriber
    def process_action(event)
      # we don't have access to the request here, so we can't just put this in the env
      Thread.current[:request_throttle_db_runtime] = (event.payload[:db_runtime] || 0) / 1000.0
    end
  end
  ActionControllerLogSubscriber.attach_to :action_controller

  def db_runtime(_request)
    Thread.current[:request_throttle_db_runtime]
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    starting_mem = Canvas.sample_memory()
    starting_cpu = Process.times()

    request = ActionController::Request.new(env)
    # workaround a rails bug where some ActionController::Request methods blow
    # up when using certain servers until fullpath is called once to set env['REQUEST_URI']
    request.fullpath

    result = nil
    bucket = LeakyBucket.new(client_identifier(request))

    bucket.reserve_capacity do
      result = if !allowed?(request, bucket)
        rate_limit_exceeded
      else
        @app.call(env)
      end

      ending_cpu = Process.times()
      ending_mem = Canvas.sample_memory()

      user_cpu = ending_cpu.utime - starting_cpu.utime
      system_cpu = ending_cpu.stime - starting_cpu.stime
      account = env["canvas.domain_root_account"]
      db_runtime = (self.db_runtime(request) || 0.0)
      report_on_stats(db_runtime, account, starting_mem, ending_mem, user_cpu, system_cpu)

      # currently we define cost as the amount of user cpu time plus the amount
      # of time spent in db queries
      cost = user_cpu + db_runtime
      cost
    end

    result
  end

  def allowed?(request, bucket)
    if whitelisted?(request)
      return true
    elsif blacklisted?(request)
      Rails.logger.info("blocking request due to blacklist, client id: #{client_identifier(request)} ip: #{request.remote_ip}")
      CanvasStatsd::Statsd.increment("request_throttling.blacklisted")
      return false
    else
      if bucket.full?
        CanvasStatsd::Statsd.increment("request_throttling.throttled")
        if Setting.get("request_throttle.enabled", "true") == "true"
          Rails.logger.info("blocking request due to throttling, client id: #{client_identifier(request)} bucket: #{bucket.to_json}")
          return false
        else
          Rails.logger.info("would block request due to throttling, client id: #{client_identifier(request)} bucket: #{bucket.to_json}")
        end
      end
      return true
    end
  end

  def blacklisted?(request)
    client_id = client_identifier(request)
    (client_id && self.class.blacklist.include?(client_id)) ||
      self.class.blacklist.include?("ip:#{request.remote_ip}")
  end

  def whitelisted?(request)
    client_id = client_identifier(request)
    return false unless client_id
    self.class.whitelist.include?(client_id)
    # we don't check the whitelist for remote_ip, whitelist is primarily
    # intended for grandfathering in some API users by access token
  end

  # This is cached on the request, so a theoretical change to the request
  # object won't be caught.
  def client_identifier(request)
    request.env['canvas.request_throttle.user_id'] ||= begin
      if token_string = AuthenticationMethods.access_token(request, :GET).presence
        identifier = AccessToken.hashed_token(token_string)
        identifier = "token:#{identifier}"
      elsif identifier = AuthenticationMethods.user_id(request).presence
        identifier = "user:#{identifier}"
      elsif identifier = session_id(request).presence
        identifier = "session:#{identifier}"
      end
      identifier
    end
  end

  def session_id(request)
    request.env['rack.session.options'].try(:[], :id)
  end

  def self.blacklist
    @blacklist ||= list_from_setting('request_throttle.blacklist')
  end

  def self.whitelist
    @whitelist ||= list_from_setting('request_throttle.whitelist')
  end

  def self.reload!
    @whitelist = @blacklist = nil
  end

  def self.list_from_setting(key)
    Set.new(Setting.get(key, '').split(',').map(&:strip).reject(&:blank?))
  end

  def rate_limit_exceeded
    [ 403,
      { 'Content-Type' => 'text/plain; charset=utf-8' },
      ["403 #{Rack::Utils::HTTP_STATUS_CODES[403]} (Rate Limit Exceeded)\n"]
    ]
  end

  def report_on_stats(db_runtime, account, starting_mem, ending_mem, user_cpu, system_cpu)
    RequestContextGenerator.add_meta_header("b", starting_mem)
    RequestContextGenerator.add_meta_header("m", ending_mem)
    RequestContextGenerator.add_meta_header("u", "%.2f" % [user_cpu])
    RequestContextGenerator.add_meta_header("y", "%.2f" % [system_cpu])
    RequestContextGenerator.add_meta_header("d", "%.2f" % [db_runtime])

    if account
      CanvasStatsd::Statsd.timing("requests_user_cpu.account_#{account.id}", user_cpu)
      CanvasStatsd::Statsd.timing("requests_system_cpu.account_#{account.id}", system_cpu)
      CanvasStatsd::Statsd.timing("requests_user_cpu.shard_#{account.shard.id}", user_cpu)
      CanvasStatsd::Statsd.timing("requests_system_cpu.shard_#{account.shard.id}", system_cpu)

      if account.shard.respond_to?(:database_server)
        CanvasStatsd::Statsd.timing("requests_system_cpu.cluster_#{account.shard.database_server.id}", system_cpu)
        CanvasStatsd::Statsd.timing("requests_user_cpu.cluster_#{account.shard.database_server.id}", user_cpu)
      end
    end

    mem_stat = if starting_mem == 0 || ending_mem == 0
                 "? ? ? ?"
               else
                 "#{starting_mem} #{ending_mem} #{ending_mem - starting_mem} #{@@last_sample}"
               end

    Rails.logger.info "[STAT] #{mem_stat} #{user_cpu} #{system_cpu}"
    @@last_sample = ending_mem
  end

  # Our leaky bucket has a separate high water mark (where the bucket is
  # considered "full") and maximum.
  # Think of the HWM as a line on the inside of the bucket, where the bucket is
  # considered full if the bucket gets filled past that line, but the bucket
  # can continue to hold more up to the maximum (top of the bucket).
  # The reason we add this to the normal leaky bucket algorithm is if maximum
  # and hwm were equal, then the bucket would always leak at least a tiny bit
  # by the beginning of the next request, and thus would never be considered
  # full.
  class LeakyBucket < Struct.new(:client_identifier, :count, :last_touched)
    def initialize(client_identifier, count = 0.0, last_touched = nil)
      super
    end

    def redis
      @redis ||= Canvas.redis.respond_to?(:node_for) ? Canvas.redis.node_for(cache_key) : Canvas.redis
    end

    # Cache this on the class, so we don't load the lua script on each request.
    def self.lua
      @lua ||= ::Redis::Scripting::Module.new(nil, File.join(File.dirname(__FILE__), "request_throttle"))
    end

    def cache_key
      "request_throttling:#{client_identifier}"
    end

    SETTING_DEFAULTS = [
      [:maximum, 800],
      [:hwm, 600],
      [:outflow, 10],
      [:up_front_cost, 50],
    ]

    SETTING_DEFAULTS.each do |(setting, default)|
      define_method(setting) do
        Setting.get("request_throttle.#{setting}", default).to_f
      end
    end

    # up_front_cost is a placeholder cost. Essentially it adds some cost to
    # doing multiple requests in parallel, but that cost is transient -- it
    # disappears again when the request finishes.
    #
    # This method does an initial increment by the up_front_cost, loading the
    # data out of redis at the same time. It then yields to the block,
    # expecting the block to return the final cost. It then increments again,
    # subtracting the initial up_front_cost from the final cost to erase it.
    def reserve_capacity(up_front_cost = self.up_front_cost)
      increment(0, up_front_cost)
      cost = yield
    ensure
      increment(cost || 0, -up_front_cost)
    end

    def full?
      count >= hwm
    end

    # This is where we both leak and then increment by the given cost amount,
    # all in lua on the redis server.
    # We do this all in lua to save on redis calls.
    # Without lua, we'd have to use a redis optimistic transaction, reading the
    # old values, and then pushing the new values. That would take at least 2
    # round trips, and possibly more when we get a transaction conflict.
    # amount and reserve_cost are passed separately for logging purposes.
    def increment(amount, reserve_cost = 0, current_time = Time.now)
      if client_identifier.blank? || !Canvas.redis_enabled?
        return
      end

      current_time = current_time.to_f
      Rails.logger.debug("request throttling increment: #{([amount, reserve_cost, current_time] + self.as_json.to_a).to_json}")
      redis = self.redis
      count, last_touched = LeakyBucket.lua.run(:increment_bucket, [cache_key], [amount + reserve_cost, current_time, outflow, maximum], redis)
      self.count = count.to_f
      self.last_touched = last_touched.to_f
    end
  end
end
end

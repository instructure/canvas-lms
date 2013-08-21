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

# unfortunately this timing data isn't exposed elsewhere,
# so we override this method to put it in the rack env
class ActionController::Base
  def active_record_runtime
    db_runtime = ActiveRecord::Base.connection.reset_runtime
    db_runtime += @db_rt_before_render if @db_rt_before_render
    db_runtime += @db_rt_after_render if @db_rt_after_render
    request.env['active_record_runtime'] = db_runtime / 1000.0 if request
    "DB: %.0f" % db_runtime
  end
end

module Canvas
class RequestThrottle
  # this @@last_sample data isn't thread-safe, and if canvas ever becomes
  # multi-threaded, we'll have to just get rid of it since we can't measure
  # per-thread heap used
  @@last_sample = 0

  def initialize(app)
    @app = app
  end

  def call(env)
    starting_mem = Canvas.sample_memory()
    starting_cpu = Process.times()

    request = ActionController::Request.new(env)
    # workaround a rails bug where some ActionController::Request methods blow
    # up when using certain servers until request_uri is called once to set env['REQUEST_URI']
    request.request_uri

    bucket = bucket(request)

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
    report_on_stats(account, starting_mem, ending_mem, user_cpu, system_cpu)

    # currently we define cost as the amount of user cpu time plus the amount
    # of time spent in db queries
    cost = user_cpu + (env['active_record_runtime'] || 0.0)
    bucket.increment(cost) if bucket

    result
  end

  def allowed?(request, bucket)
    if whitelisted?(request)
      return true
    elsif blacklisted?(request)
      Rails.logger.info("blocking request due to blacklist, client id: #{client_identifier(request)} ip: #{request.remote_ip}")
      Canvas::Statsd.increment("request_throttling.blacklisted")
      return false
    else
      if bucket
        bucket.load_data()
        if bucket.full?
          Rails.logger.info("blocking request due to throttling, client id: #{client_identifier(request)} bucket: #{bucket.to_json}")
          Canvas::Statsd.increment("request_throttling.throttled")
          return false
        end
      end
      return true
    end
  end

  def blacklisted?(request)
    client_id = client_identifier(request)
    (client_id && self.class.blacklist.include?(client_id)) ||
      self.class.blacklist.include?(request.remote_ip)
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
    request.env['canvas.request_throttle.user_id'] ||=
      (AuthenticationMethods.access_token(request, :GET) ||
       AuthenticationMethods.user_id(request) ||
       session_id(request)).to_s.presence
  end

  def session_id(request)
    request.env['rack.session.options'].try(:[], :id)
  end

  def bucket(request)
    request.env['canvas.request_throttle.bucket'] ||=
      if Canvas.redis_enabled? && client_id = client_identifier(request)
        LeakyBucket.new(client_id)
      else
        nil
      end
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
    Set.new(Setting.get(key, '').split(',').map(&:strip))
  end

  def rate_limit_exceeded
    [ 403,
      { 'Content-Type' => 'text/plain; charset=utf-8' },
      ["403 #{Rack::Utils::HTTP_STATUS_CODES[403]} (Rate Limit Exceeded)\n"]
    ]
  end

  def report_on_stats(account, starting_mem, ending_mem, user_cpu, system_cpu)
    if account
      Canvas::Statsd.timing("requests_user_cpu.account_#{account.id}", user_cpu)
      Canvas::Statsd.timing("requests_system_cpu.account_#{account.id}", system_cpu)
      Canvas::Statsd.timing("requests_user_cpu.shard_#{account.shard.id}", user_cpu)
      Canvas::Statsd.timing("requests_system_cpu.shard_#{account.shard.id}", system_cpu)

      if account.shard.respond_to?(:database_server)
        Canvas::Statsd.timing("requests_system_cpu.cluster_#{account.shard.database_server.id}", system_cpu)
        Canvas::Statsd.timing("requests_user_cpu.cluster_#{account.shard.database_server.id}", user_cpu)
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
      raise(ArgumentError, "client_identifier required") unless client_identifier.present?
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

    [[:maximum, 800], [:hwm, 600], [:outflow, 10]].each do |(setting, default)|
      define_method(setting) do
        Setting.get_cached("request_throttle.#{setting}", default).to_f
      end
    end

    def load_data
      count, last_touched = redis.hmget(cache_key, "count", "last_touched")
      self.count = (count || 0.0).to_f
      self.last_touched = (last_touched || Time.now).to_f
    end

    def full?(current_time = Time.now)
      new_count = leak(current_time)
      new_count >= hwm
    end

    # This same leak logic is implemented in the lua script.
    # Note that this leaking applies only locally to the current process, it
    # isn't saved back to redis. That redis update happens purely in lua.
    def leak(current_time)
      new_count = self.count
      if new_count > 0
        timespan = current_time - Time.at(self.last_touched)
        loss = outflow * timespan
        if loss > 0
          if loss > new_count
            loss = new_count
          end
          new_count -= loss
        end
      end
      new_count
    end

    # This is where we both leak and then increment by the given cost amount,
    # all in lua on the redis server.
    # We do this all in lua to save on redis calls.
    # Without lua, we'd have to use a redis optimistic transaction, reading the
    # old values, and then pushing the new values. That would take at least 2
    # round trips, and possibly more when we get a transaction conflict.
    def increment(amount, current_time = Time.now)
      current_time = current_time.to_f
      Rails.logger.debug("request throttling increment: #{([amount, current_time] + self.as_json).to_json}")
      count, last_touched = LeakyBucket.lua.run(:increment_bucket, [cache_key], [amount, current_time, outflow, maximum], redis)
      self.count = count.to_f
      self.last_touched = last_touched.to_f
    end
  end
end
end

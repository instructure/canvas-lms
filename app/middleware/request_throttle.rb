# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class RequestThrottle
  attr_accessor :inst_access_token_authentication

  # this @@last_sample data isn't thread-safe, and if canvas ever becomes
  # multi-threaded, we'll have to just get rid of it since we can't measure
  # per-thread heap used
  @@last_sample = 0

  SERVICE_HEADER_EXPRESSION = %r{^inst-[a-z0-9_-]+/[a-z0-9]+.*$}i

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
    @inst_access_token_authentication = nil
  end

  def call(env)
    starting_mem = Canvas.sample_memory
    starting_cpu = Process.times

    request = ActionDispatch::Request.new(env)
    self.inst_access_token_authentication = ::AuthenticationMethods::InstAccessToken::Authentication.new(
      request
    )

    # NOTE: calling fullpath was a workaround for a rails bug where some ActionDispatch::Request methods blow
    # up when using certain servers until fullpath is called once to set env['REQUEST_URI']
    # so don't remove
    path = request.fullpath

    status, headers, response = nil
    throttled = false
    bucket = LeakyBucket.new(client_identifier(request))

    up_front_cost = bucket.get_up_front_cost_for_path(path)
    pre_judged = approved?(request) || blocked?(request)
    cost = bucket.reserve_capacity(up_front_cost, request_prejudged: pre_judged) do
      status, headers, response = if allowed?(request, bucket)
                                    @app.call(env)
                                  else
                                    throttled = true
                                    rate_limit_exceeded
                                  end

      ending_cpu = Process.times
      ending_mem = Canvas.sample_memory

      user_cpu = ending_cpu.utime - starting_cpu.utime
      system_cpu = ending_cpu.stime - starting_cpu.stime
      account = env["canvas.domain_root_account"]
      db_runtime = self.db_runtime(request) || 0.0
      report_on_stats(db_runtime, account, starting_mem, ending_mem, user_cpu, system_cpu)
      cost = calculate_cost(user_cpu, db_runtime, env)
      cost
    end

    if client_identifier(request) && !client_identifier(request).starts_with?("session")
      headers["X-Request-Cost"] = cost.to_s unless throttled
      headers["X-Rate-Limit-Remaining"] = bucket.remaining.to_s
      headers["X-Rate-Limit-Remaining"] = 0.0.to_s if blocked?(request)
    end

    [status, headers, response]
  end

  # currently we define cost as the amount of user cpu time plus the amount
  # of time spent in db queries, plus any arbitrary cost the app assigns.
  # The CPU and DB costs are weighted according to settings so they
  # can be dialed up or down individually if we need to have them contribute more or
  # less to overall throttling behaviour.  Overall throttling prevelency
  # not related to any specific subcategory of time sinks should be controlled by tuning the
  # "request_throttle.outflow" setting instead, which impacts how quickly
  # the bucket leaks.
  def calculate_cost(user_time, db_time, env)
    extra_time = env.fetch("extra-request-cost", 0)
    extra_time = 0 unless extra_time.is_a?(Numeric) && extra_time >= 0
    cpu_cost = Setting.get("request_throttle.cpu_cost_weight", "1.0").to_f
    db_cost = Setting.get("request_throttle.db_cost_weight", "1.0").to_f
    (user_time * cpu_cost) + (db_time * db_cost) + extra_time
  end

  def subject_to_throttling?(request)
    self.class.enabled? && Canvas.redis_enabled? && !approved?(request) && !blocked?(request)
  end

  def allowed?(request, bucket)
    if approved?(request)
      true
    elsif blocked?(request)
      # blocking is useful even if throttling is disabled, this is left in intentionally
      Rails.logger.info("blocking request due to blocklist, client id: #{client_identifiers(request).inspect} ip: #{request.remote_ip}")
      InstStatsd::Statsd.increment("request_throttling.blocked")
      false
    else
      if bucket.full?
        if RequestThrottle.enabled?
          InstStatsd::Statsd.increment("request_throttling.throttled")
          Rails.logger.info("blocking request due to throttling, client id: #{client_identifier(request)} bucket: #{bucket.to_json}")
          return false
        else
          Rails.logger.info("WOULD HAVE throttled request (config disabled), client id: #{client_identifier(request)} bucket: #{bucket.to_json}")
        end
      end
      true
    end
  end

  def blocked?(request)
    return true if inst_access_token_authentication&.blocked?

    client_identifiers(request).any? { |id| self.class.blocklist.include?(id) }
  end

  def approved?(request)
    client_identifiers(request).any? { |id| self.class.approvelist.include?(id) }
  end

  def client_identifier(request)
    client_identifiers(request).first
  end

  def tag_identifier(tag, identifier)
    return unless identifier

    "#{tag}:#{identifier}"
  end

  # This is cached on the request, so a theoretical change to the request
  # object won't be caught.
  def client_identifiers(request)
    request.env["canvas.request_throttle.user_id"] ||= [
      tag_identifier("lti_advantage", lti_advantage_client_id_and_cluster(request)),
      tag_identifier("service_user_key", site_admin_service_user_key(request)),
      tag_identifier("service_user_key", inst_access_token_authentication&.tag_identifier),
      (token_string = AuthenticationMethods.access_token(request, :GET).presence) && "token:#{AccessToken.hashed_token(token_string)}",
      tag_identifier("user", AuthenticationMethods.user_id(request).presence),
      tag_identifier("session", session_id(request).presence),
      tag_identifier("tool", tool_id(request)),
      tag_identifier("ip", request.ip)
    ].compact
  end

  # Bucket based on LTI Advantage client_id. Routes are identified by a combination of path
  # and whether the controller uses the LtiServices concern -- see lti_advantage_route? method.
  def lti_advantage_client_id_and_cluster(request)
    return unless Lti::IMS::AdvantageAccessTokenRequestHelper.lti_advantage_route?(request)

    client_id = Lti::IMS::AdvantageAccessTokenRequestHelper.token(request)&.client_id
    return unless client_id

    cluster_id = request.env["canvas.domain_root_account"]&.shard&.database_server_id
    "#{client_id}-#{cluster_id}"
  rescue Lti::IMS::AdvantageErrors::AdvantageClientError
    nil
  end

  def tool_id(request)
    return unless request.request_method_symbol == :post && request.fullpath =~ %r{/api/lti/v1/tools/([^/]+)/(?:ext_)?grade_passback}

    tool_id = $1
    return unless Api::ID_REGEX.match?(tool_id)

    # yes, a db lookup, but we're only loading it for these two actions,
    # and only if another identifier couldn't be found
    tool = ContextExternalTool.find_by(id: tool_id)
    return unless tool

    tool.domain
  end

  def session_id(request)
    request.env["rack.session.options"].try(:[], :id)
  end

  def site_admin_service_user_key(request)
    # We only want to allow this approvelist method for User-Agent strings that match the following format:
    # Example (short): `inst-service-name/2d0c1jk2`
    # Example (full): `inst-service-name/2d0c1jk2 (region: us-east-1; host: 1de983c20j1ak2; env: production)`
    return unless SERVICE_HEADER_EXPRESSION.match?(request.user_agent)

    return unless (token_string = AuthenticationMethods.access_token(request))

    return unless AccessToken.site_admin?(token_string)

    AccessToken.authenticate(token_string).global_developer_key_id
  end

  def service_user_jwt_key(request)
    AuthenticationMethods::InstAccessToken.tag_identifier(request)
  end

  def self.blocklist
    @blocklist ||= list_from_setting("request_throttle.blocklist")
  end

  def self.approvelist
    @approvelist ||= list_from_setting("request_throttle.approvelist")
  end

  def self.reload!
    @approvelist = @blocklist = @dynamic_settings = nil
    LeakyBucket.reload!
  end

  def self.enabled?
    Setting.get("request_throttle.enabled", "true") == "true"
  end

  def self.list_from_setting(key)
    Set.new(Setting.get(key, "").split(",").map { |i| i.gsub(/^\s+|\s*(?:;.+)?\s*$/, "") }.compact_blank)
  end

  def self.dynamic_settings
    unless @dynamic_settings
      consul_data = DynamicSettings.find(tree: :private)["request_throttle.yml", failsafe: :missing] || ""
      return {} if consul_data == :missing

      @dynamic_settings = YAML.safe_load(consul_data) || {}
    end
    @dynamic_settings
  end

  def rate_limit_exceeded
    [403,
     { "Content-Type" => "text/plain; charset=utf-8", "X-Rate-Limit-Remaining" => "0.0" },
     ["403 #{Rack::Utils::HTTP_STATUS_CODES[403]} (Rate Limit Exceeded)\n"]]
  end

  def report_on_stats(db_runtime, account, starting_mem, ending_mem, user_cpu, system_cpu)
    RequestContext::Generator.add_meta_header("b", starting_mem)
    RequestContext::Generator.add_meta_header("m", ending_mem)
    RequestContext::Generator.add_meta_header("u", "%.2f" % [user_cpu])
    RequestContext::Generator.add_meta_header("y", "%.2f" % [system_cpu])
    RequestContext::Generator.add_meta_header("d", "%.2f" % [db_runtime])

    if account&.shard&.database_server
      InstStatsd::Statsd.timing("requests_system_cpu.cluster_#{account.shard.database_server.id}",
                                system_cpu,
                                short_stat: "requests_system_cpu",
                                tags: { cluster: account.shard.database_server.id })
      InstStatsd::Statsd.timing("requests_user_cpu.cluster_#{account.shard.database_server.id}",
                                user_cpu,
                                short_stat: "requests_user_cpu",
                                tags: { cluster: account.shard.database_server.id })
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
  LeakyBucket = Struct.new(:client_identifier, :count, :last_touched) do # rubocop:disable Lint/StructNewOverride
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

    {
      maximum: 800,
      hwm: 600,
      outflow: 10,
      up_front_cost: 50,
    }.each do |(setting, default)|
      define_method(setting) do
        (self.class.custom_settings_hash[client_identifier]&.[](setting.to_s) ||
          Setting.get("request_throttle.#{setting}", default)).to_f
      end
    end

    def self.custom_settings_hash
      @custom_settings_hash ||= begin
        JSON.parse(
          Setting.get("request_throttle.custom_settings", "{}")
        )
      rescue JSON::JSONError
        {}
      end
    end

    def self.up_front_cost_by_path_regex
      @up_front_cost_regex_map ||=
        begin
          hash = RequestThrottle.dynamic_settings["up_front_cost_by_path_regex"] || {}
          hash.keys.select { |k| k.is_a?(String) }.map { |k| hash[Regexp.new(k)] = hash.delete(k) } # regexify strings
          hash.each do |k, v|
            next if k.is_a?(Regexp) && v.is_a?(Numeric)

            ::Rails.logger.error("ERROR in request_throttle.yml: up_front_cost_by_path_regex must use Regex => Numeric key-value pairs")
            hash.clear
            break
          end
          hash
        end
    end

    def self.reload!
      @custom_settings_hash = nil
      @up_front_cost_regex_map = nil
    end

    # up_front_cost is a placeholder cost. Essentially it adds some cost to
    # doing multiple requests in parallel, but that cost is transient -- it
    # disappears again when the request finishes.
    def get_up_front_cost_for_path(path)
      # if it matches any of the regexes in the setting, return the specified cost
      self.class.up_front_cost_by_path_regex.each do |regex, cost|
        return cost if regex&.match?(path)
      end
      up_front_cost # otherwise use the default
    end

    # This method does an initial increment by the up_front_cost, loading the
    # data out of redis at the same time. It then yields to the block,
    # expecting the block to return the final cost. It then increments again,
    # subtracting the initial up_front_cost from the final cost to erase it.
    def reserve_capacity(up_front_cost = self.up_front_cost, request_prejudged: false)
      increment(0, up_front_cost) unless request_prejudged
      cost = yield
    ensure
      increment(cost || 0, -up_front_cost) unless request_prejudged
    end

    def full?
      count >= hwm
    end

    def remaining
      hwm - count
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
      Rails.logger.debug("request throttling increment: #{([amount, reserve_cost, current_time] + as_json.to_a).to_json}")
      count, last_touched = LeakyBucket.lua.run(:increment_bucket, [cache_key], [amount + reserve_cost, current_time, outflow, maximum], redis)
      self.count = count.to_f
      self.last_touched = last_touched.to_f
    rescue Redis::BaseConnectionError
      # ignore
    end
  end
end

Canvas::Reloader.on_reload { RequestThrottle.reload! }

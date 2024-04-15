# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require "datadog/tracing"

module Canvas
  # This module is currently a wrapper for managing connecting with ddtrace
  # to send APM information to Datadog, but could in the future be re-worked to
  # be configurable for multiple APM backends.
  #
  # use Canvas::Apm.enable_debug_mode = true to force logging output
  # for every trace we try to write.  Useful for making sure you're getting
  # the tags you want at the client level, etc.
  #
  # Expected use is to call "configure_apm!" from an initializer
  # (see /config/initializers/datadog_apm.rb)
  # to configure APM and instrument rails in general.
  #
  # in contexts where we have canvas-specific attributes available,
  #  calling Canvas::Apm.annotate_trace() with the shard and account
  #  will provide the facets useful for searching by in the aggregation client.
  module Apm
    HOST_SAMPLING_INTERVAL = 10_000
    class << self
      attr_writer :enable_debug_mode, :hostname, :tracer

      def reset!
        @_app_analytics_enabled = nil
        @_config = nil
        @_host_sample_rate = nil
        @_host_sampling_decision = nil
        @_sample_rate = nil
        @enable_debug_mode = nil
        @hostname = nil
        @tracer = nil
      end

      def config
        unless @_config

          return @_config if @_config.present?

          dynamic_settings = DynamicSettings.find(tree: :private)
          yaml = dynamic_settings["datadog_apm.yml", failsafe: :missing] || "{}"
          return {} if yaml == :missing

          @_config = YAML.safe_load(yaml)
        end
        @_config
      end

      def sample_rate
        return @_sample_rate if @_sample_rate.present?

        @_sample_rate = config.fetch("sample_rate", 0.0).to_f
      end

      def host_sample_rate
        return @_host_sample_rate if @_host_sample_rate.present?

        @_host_sample_rate = config.fetch("host_sample_rate", 0.0).to_f
      end

      def analytics_enabled?
        return @_app_analytics_enabled unless @_app_analytics_enabled.nil?

        @_app_analytics_enabled = config.fetch("app_analytics_enabled", false)
      end

      def configured?
        sample_rate > 0.0 && host_chosen?
      end

      def host_chosen?
        return @_host_sampling_decision if @_host_sampling_decision.present?
        return false if @hostname.blank? || host_sample_rate <= 0
        return false if host_sample_rate > 1.0 # invalid ratio

        @_host_sampling_decision = get_sampling_decision(@hostname, host_sample_rate, HOST_SAMPLING_INTERVAL)
      end

      def get_sampling_decision(string_input, rate, interval)
        # SHA is consistent across machines
        # and ruby invocations.  Same host and
        # sampling ratio will always produce same decision.
        # this is important because we get billed by host
        # and we want all the passenger processes on a single
        # host to make the same decision.
        sha = Digest::SHA1.hexdigest(string_input)
        sha_int = sha.to_i(16)
        interval_point = sha_int % interval
        threshold = rate * interval
        interval_point <= threshold
      end

      def rate_sampler
        Datadog::Tracing::Sampling::RateSampler.new(sample_rate)
      end

      def enable_apm!
        sampler = rate_sampler
        debug_mode = @enable_debug_mode.presence || false
        Datadog.configure do |c|
          # this is filtered on the datadog UI side
          # to make sure we don't analyze _everything_
          # which would be very expensive
          c.tracing.analytics.enabled = analytics_enabled?
          c.diagnostics.debug = debug_mode
          c.tracing.sampler = sampler
          c.tracing.instrument :aws
          c.tracing.instrument :faraday
          c.tracing.instrument :graphql
          c.tracing.instrument :http
          c.tracing.instrument :rails
          c.tracing.instrument :redis
        end
        Delayed::Worker.plugins << Canvas::Apm::InstJobs::Plugin
      end

      def configure_apm!
        enable_apm! if configured?
      end

      def annotate_trace(shard, root_account, request_context_id, current_user)
        return unless configured?

        apm_root_span = tracer.active_root_span
        return if apm_root_span.blank?

        apm_root_span.set_tag("request_context_id", request_context_id.to_s) if request_context_id.present?
        apm_root_span.set_tag("shard", shard.id.to_s) if shard.try(:id).present?
        act_global_id = root_account.try(:global_id)
        apm_root_span.set_tag("root_account", act_global_id.to_s) if act_global_id.present?
        apm_root_span.set_tag("current_user", current_user.global_id.to_s) if current_user
      end

      # use this to wrap arbitrary code in traces
      # without referencing the datadog library directly
      # while still getting to avoid (for now) having to wrap
      # every possible option in their API.
      #
      # To trace any Ruby code, you can use the Canvas::Apm.tracer.trace method:
      #
      # Canvas::Apm.tracer.trace(name, options) do |span|
      #   # Wrap this block around the code you want to instrument
      #   # Additionally, you can modify the span here.
      #   # e.g. Change the resource name, set tags, etc...
      # end
      #
      # See datadog examples here:
      # http://gems.datadoghq.com/trace/docs/#Manual_Instrumentation
      def tracer
        return Canvas::Apm::StubTracer.instance unless configured?

        @tracer || Datadog::Tracing
      end

      # Alternatively you can just call this to get
      # the service name and trace type preset for you
      #
      # Canvas::Apm.trace("timezone setup", options) do |span|
      #  # the code to trace goes here
      # end
      #
      # see available "Options" to be passed on here:
      # http://gems.datadoghq.com/trace/docs/#Manual_Instrumentation
      def trace(resource_name, opts = {}, &)
        opts[:service] = opts.fetch(:service, "canvas_custom")
        opts[:resource] = resource_name
        opts[:span_type] = opts.fetch(:span_type, "canvas_ruby")
        tracer.trace("application.code", opts, &)
      end
    end
  end
end

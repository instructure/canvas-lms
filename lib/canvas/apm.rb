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

require 'ddtrace'
require 'digest/sha1'
require 'canvas/dynamic_settings'

module Canvas
  # This module is currently a wrapper for managing connecting with ddtrace
  # to send APM information to Datadog, but could in the future be re-worked to
  # be configurable for multiple APM backends.
  #
  # If running with multiple database clusters in production,
  # you can set the "canvas_cluster" variable before enabling APM
  # to make sure each cluster can load it's settings (for sampling rate)
  # individually.
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
    HOST_SAMPLING_INTERVAL = 10000
    class << self
      attr_writer :enable_debug_mode, :hostname
      attr_accessor :canvas_cluster

      def reset!
        @canvas_cluster = nil
        @_config = nil
        @_sample_rate = nil
        @_host_sample_rate = nil
        @enable_debug_mode = nil
        @hostname = nil
      end

      def config
        return @_config if @_config.present?
        dynamic_settings = Canvas::DynamicSettings.find(tree: :private)
        if self.canvas_cluster.present?
          dynamic_settings = Canvas::DynamicSettings.find(tree: :private, cluster: self.canvas_cluster)
        end
        @_config = YAML.safe_load(dynamic_settings['datadog_apm.yml'] || '{}')
      end

      def sample_rate
        return @_sample_rate if @_sample_rate.present?
        @_sample_rate = self.config.fetch('sample_rate', 0.0).to_f
      end

      def host_sample_rate
        return @_host_sample_rate if @_host_sample_rate.present?
        @_host_sample_rate = self.config.fetch('host_sample_rate', 0.0).to_f
      end

      def configured?
        self.sample_rate > 0.0 && host_chosen?
      end

      def host_chosen?
        return false if @hostname.blank? || host_sample_rate <= 0
        return false if host_sample_rate > 1.0 # invalid ratio
        get_sampling_decision(@hostname, host_sample_rate, HOST_SAMPLING_INTERVAL)
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
        Datadog::RateSampler.new(self.sample_rate)
      end

      def enable_apm!
        sampler = self.rate_sampler
        debug_mode = @enable_debug_mode.presence || false
        Datadog.configure do |c|
          c.tracer sampler: sampler, debug: debug_mode
          c.use :aws
          c.use :faraday
          c.use :graphql
          c.use :http
          c.use :rails
          c.use :redis
        end
        Delayed::Worker.plugins << Canvas::Apm::InstJobs::Plugin
      end

      def configure_apm!
        self.enable_apm! if self.configured?
      end

      def annotate_trace(shard, root_account, request_context_id, current_user)
        return unless self.configured?
        apm_root_span = Datadog.tracer.active_root_span
        return if apm_root_span.blank?
        apm_root_span.set_tag('request_context_id', request_context_id.to_s) if request_context_id.present?
        apm_root_span.set_tag('shard', shard.id.to_s) if shard.try(:id).present?
        act_global_id = root_account.try(:global_id)
        apm_root_span.set_tag('root_account', act_global_id.to_s) if act_global_id.present?
        apm_root_span.set_tag('current_user', current_user.global_id.to_s) if current_user
      end
    end
  end
end
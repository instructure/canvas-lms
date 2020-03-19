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

module Canvas
  # This class is currently a wrapper for managing connecting with ddtrace
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
  class Apm
    class << self
      attr_writer :enable_debug_mode
      attr_accessor :canvas_cluster

      def reset!
        @canvas_cluster = nil
        @_config = nil
        @_sample_rate = nil
        @enable_debug_mode = nil
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

      def configured?
        self.sample_rate > 0.0
      end

      def rate_sampler
        Datadog::RateSampler.new(self.sample_rate)
      end

      def enable_apm!
        sampler = self.rate_sampler
        debug_mode = @enable_debug_mode.presence || false
        Datadog.configure do |c|
          c.tracer sampler: sampler, debug: debug_mode
          c.use :rails
        end
      end

      def configure_apm!
        self.enable_apm! if self.configured?
      end

      def annotate_trace(shard, root_account)
        return unless self.configured?
        apm_root_span = Datadog.tracer.active_root_span
        return if apm_root_span.blank?
        apm_root_span.set_tag('shard', shard.id.to_s) if shard.try(:id).present?
        act_global_id = root_account.try(:global_id)
        apm_root_span.set_tag('root_account', act_global_id.to_s) if act_global_id.present?
      end
    end
  end
end
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

module DatadogApmConfig
  class << self
    def config
      dynamic_settings = Canvas::DynamicSettings.find(tree: :private)
      if $canvas_cluster
        dynamic_settings = Canvas::DynamicSettings.find(tree: :private, cluster: $canvas_cluster)
      end
      YAML.safe_load(dynamic_settings['datadog_apm.yml'] || '{}')
    end

    def sample_rate
      config.fetch('sample_rate', 0.0).to_f
    end

    def configured?
      sample_rate > 0.0
    end

    def rate_sampler
      Datadog::RateSampler.new(self.sample_rate)
    end

    def enable_apm!
      sampler = self.rate_sampler
      Datadog.configure do |c|
        c.tracer sampler: sampler
        c.use :rails
      end
    end
  end
end

if DatadogApmConfig.configured?
  DatadogApmConfig.enable_apm!
end
# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# This helper is used to track timing information via inst_statsd.
# TODO: This should be moved to inst_statsd
module Utils
  module InstStatsdUtils
    class TimingMeta
      attr_accessor :tags

      def initialize(tags)
        @tags = tags
      end
    end

    class Timing
      # Use this method to time a block of code. The name is the name of the metric
      # sent to datadog. The block is passed an empty hash which can be used
      # to add tags to the metric.
      # Example:
      #   Utils::InstStatsdUtils::Timing.track('my.metric') do |meta|
      #     ...
      #     meta.tags = {
      #       tag1: 'value1',
      #       tag2: 'value2'
      #     }
      #   end
      def self.track(name)
        timing_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        timing_meta = TimingMeta.new({})
        yield(timing_meta)
      ensure
        timing_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        InstStatsd::Statsd.timing(name, timing_end - timing_start, tags: timing_meta.tags || {})
      end
    end
  end
end

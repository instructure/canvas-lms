#
# Copyright (C) 2012 Instructure, Inc.
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

# Proxy class to communicate messages to statsd
# Available statsd messages are described in:
#   https://github.com/etsy/statsd/blob/master/README.md
#   https://github.com/reinh/statsd/blob/master/lib/statsd.rb
#
# So for instance:
#   ms = Benchmark.ms { ..code.. }
#   CanvasStatsd::Statsd.timing("my_stat", ms)
#
# Configured in config/statsd.yml, see config/statsd.yml.example
# At least a host needs to be defined for the environment, all other config is optional
#
# If a namespace is defined in statsd.yml, it'll be prepended to the stat name.
# The hostname of the server will be appended to the stat name, unless `append_hostname: false` is specified in the config.
# So if the namespace is "canvas" and the hostname is "app01", the final stat name of "my_stat" would be "stats.canvas.my_stat.app01"
# (assuming the default statsd/graphite configuration)
#
# If statsd isn't configured and enabled, then calls to CanvasStatsd::Statsd.* will do nothing and return nil

module CanvasStatsd
  module Statsd
    # replace "." in key names with another character to avoid creating spurious sub-folders in graphite
    def self.escape(str, replacement = '_')
      str.gsub('.', replacement)
    end

    def self.hostname
      @hostname ||= Socket.gethostname.split(".").first
    end

    %w(increment decrement count gauge timing).each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__+1
      def self.#{method}(stat, *args)
        if self.instance
          if self.append_hostname?
            stat_name = "\#{stat}.\#{hostname}"
          else
            stat_name = stat.to_s
          end
          self.instance.#{method}(stat_name, *args)
        else
          nil
        end
      end
      RUBY
    end

    def self.time(stat, sample_rate=1)
      start = Time.now
      result = yield
      self.timing(stat, ((Time.now - start) * 1000).round, sample_rate)
      result
    end

    def self.instance
      if !defined?(@statsd)
        statsd_settings = CanvasStatsd.settings

        if statsd_settings && statsd_settings[:host]
          @statsd = ::Statsd.new(statsd_settings[:host])
          @statsd.port = statsd_settings[:port] if statsd_settings[:port]
          @statsd.namespace = statsd_settings[:namespace] if statsd_settings[:namespace]
          @append_hostname = !statsd_settings.key?(:append_hostname) || !!statsd_settings[:append_hostname]
        else
          @statsd = nil
        end
      end
      @statsd
    end

    def self.append_hostname?
      @append_hostname
    end

    def self.reset_instance
      remove_instance_variable(:@statsd) if defined?(@statsd)
    end
  end
end

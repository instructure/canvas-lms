# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
module Canvas
  class FailurePercentCounter
    def initialize(redis, redis_key, period = 60.seconds, min_samples = 100)
      @redis = redis
      @count_key = "{#{redis_key}}:total_count"
      @fail_key = "{#{redis_key}}:fail"
      @period = period
      @min_samples = min_samples
    end

    def self.lua
      @lua ||= ::Redis::Scripting::Module.new(nil,
                                              File.join(File.dirname(__FILE__), "failure_percent_counter"))
    end

    def increment_count
      increment(@count_key)
    end

    def increment_failure
      increment(@fail_key)
    end

    def failure_rate
      now = Time.now.utc.to_i
      result = FailurePercentCounter.lua.run(:failure_rate,
                                             [@count_key],
                                             [@fail_key, now, @period, @min_samples],
                                             @redis,
                                             failsafe: 0.0)
      result.to_f
    end

    private

    def increment(key)
      now = Time.now.utc.to_i
      FailurePercentCounter.lua.run(:increment_counter,
                                    [@count_key],
                                    [key, now, SecureRandom.uuid, @period.ceil],
                                    @redis,
                                    failsafe: nil)
    end
  end
end

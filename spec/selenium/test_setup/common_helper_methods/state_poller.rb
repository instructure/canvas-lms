# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module StatePoller
  WAIT_STEP = 0.010
  WAIT_STEP_GROWTH = 1.3
  WAIT_STEP_CAP = 0.250

  class << self
    # The method implements specific poll wait sequence pattern. The provided "block" is called until
    # it returns the "expected" response or the "timeout" expires.
    def await(expected, timeout = nil)
      start = Time.now.to_f
      deadline = start + ((timeout || SeleniumDriverSetup.timeouts[:script]) * rerun_timeout_multiplier)
      wait = WAIT_STEP

      while (got = yield) != expected && Time.now.to_f < deadline
        sleep(wait)
        wait = next_wait(wait)
      end
      spent = f3(Time.now.to_f - start)
      { got:, spent: }
    end

    private

    # Method returning a timeout multiplier that is used to extend the poll timeout.
    # This should allow tests hitting performance degradation to still finish
    # their functional validation role on the test rerun
    def rerun_timeout_multiplier
      if ENV["ERROR_CONTEXT_BASE_PATH"].nil?
        1
      elsif ENV["ERROR_CONTEXT_BASE_PATH"].match?("Rerun_1")
        1.5
      else
        2
      end
    end

    # Next wait time is calculated using exponential growth function and capped at predefined level
    def next_wait(wait)
      (wait < WAIT_STEP_CAP) ? [wait * WAIT_STEP_GROWTH, WAIT_STEP_CAP].min : wait
    end

    def f3(float)
      format("%1.3f", float)
    end
  end
end

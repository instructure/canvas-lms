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

if Rails.env.test?

  # This prevents timeouts from occurring once you've started debugging a
  # process. It hooks into the specific raise used by Timeout, and if we're
  # in a debugging mood (i.e. we have ever broken into the debugger), it
  # ignores the exception. Otherwise, it's business as usual.
  #
  # This is useful so that you can debug specs (which are run in a timeout
  # block), or simply debug anything in canvas that has timeouts
  #
  # Notes:
  #  * Byebug prevents the timeout thread from even running when you are
  #    inside the debugger (it resumes afterward), so basically we just
  #    have to disable timeouts altogether if you have ever debugger'd
  #  * In a similar vein, although the timeout thread does run while Pry
  #    is doing its thing, there's not an easy way to know when you are
  #    done Pry-ing, so we just turn it off there as well.
  #
  module NoRaiseTimeoutsWhileDebugging
    def raise(*args)
      if defined?(SpecTimeLimit) && args.first == SpecTimeLimit::Error && ever_run_a_debugger?
        Rails.logger.warn "Ignoring timeout because we're debugging"
        return
      end
      super
    end

    def ever_run_a_debugger?
      defined?(::DEBUGGER__::Session) ||
        (defined?(Byebug) && Byebug.respond_to?(:started?)) ||
        (defined?(Pry) && Pry::InputLock.input_locks.any?)
    end

    module_function :ever_run_a_debugger?
  end

  Thread.prepend(NoRaiseTimeoutsWhileDebugging)
end

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

require_relative '../errors'

module Canvas
  class Errors
    class Reporter
      def self.raise_canvas_error(existing_exception_class, message, opts={})
        # This little bit of code lets you add meta data to your existing exceptions, without having to
        # modify the exception, create a new exception (and updating rescues)!
        #
        # this was the best we could come up with to accomplish the following
        # - Add metadata to the exception by adding a `canvas_error_info` method
        # - Couldn't modify existing_exception_class directly
        # - New exceptions needs to be rescue-able by rescues for the existing_exception_class
        #
        # Now anytime you want to add metadata to an exception you do:
        # ```
        # raise Canvas::Errors::Reporter.raise_canvas_error(BasicLTI::BasicOutcomes::Unauthorized, "Duplicate nonce detected", oauth_error_info)
        # ```
        err = existing_exception_class.new(message)
        err.instance_variable_set(:@canvas_error_info, opts)
        class << err
          attr_reader :canvas_error_info
        end

        # this makes the stack trace originate from the call before this one
        raise err, message, caller
      end
    end
  end
end

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

module Canvas
  # The central message bus for errors in canvas.
  #
  # This class is injected both in ApplicationController for capturing
  # exceptions that happen in request/response cycles, and in our
  # Delayed::Job callback for failed jobs.  We also call out to it
  # from several points throughout the codebase directly to register
  # an unexpected occurance that doesn't necessarily bubble up to
  # that point.
  #
  # There's a sentry connector built into canvas, but anything one
  # wants to do with errors can be hooked into this path with the
  # .register! method.
  class Errors
    # normally we would alias Errors to be CanvasErrors
    # as the shim, but we have several other classes actually inside
    # lib/canvas/errors/*.rb that need the existing module structure,
    # so method_missing works better at the moment.
    class << self
      def method_missing(...)
        CanvasErrors.send(...)
      end
    end

    JobInfo = ::CanvasErrors::JobInfo
  end
end

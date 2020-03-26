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
#
module Canvas
  module Apm
    # if this host we're running on
    # was not chosen, we don't want renegade
    # traces making it out to the agent (we'll get billed for them).
    # This class shadows the api of the datadog tracer allowing canvas code
    # to always trace without concern about whether it's enabled for a given host or not.
    class StubTracer
      include Singleton

      class StubSpan
        include Singleton

        def set_tag(key, value=nil); end

        def set_metric(key, value=nil); end

        def to_h
          {}
        end
      end

      def trace(_name, _opts={})
        yield StubSpan.instance
      end
    end
  end
end
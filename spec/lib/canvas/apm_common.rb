# frozen_string_literal: true

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

shared_context "apm" do
  let(:tracer) do
    tracer_class = Class.new do
      attr_reader :span

      def initialize
        span_class = Class.new do
          attr_reader :tags
          attr_accessor :resource, :span_type

          def initialize
            reset!
          end

          def reset!
            @tags = {}
          end

          def set_tag(key, val)
            @tags[key] = val
          end

          def get_tag(key)
            @tags[key]
          end
        end
        @span = span_class.new
      end

      def trace(_name, opts = {})
        span.resource = opts.fetch(:resource, nil)
        yield span
      end

      def active_root_span
        @span
      end

      def enabled
        true
      end
    end

    tracer_class.new
  end
  let(:span) { tracer.span }
end

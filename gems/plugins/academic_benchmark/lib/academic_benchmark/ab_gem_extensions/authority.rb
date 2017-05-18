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

require_relative 'common'

module AcademicBenchmarks
  module Standards
    class Authority
      include Common
      def document_cache
        @document_cache ||= {}
      end

      def build_outcomes(ratings={}, _parent=nil)
        document_cache.clear
        build_common_outcomes(ratings).merge!({
          title: description,
          description: "#{code} - #{description}",
        })
      end
    end
  end
end

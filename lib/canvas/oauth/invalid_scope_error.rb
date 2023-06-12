# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Canvas::OAuth
  class InvalidScopeError < RequestError
    def initialize(missing_scopes)
      super("A requested scope is invalid, unknown, malformed, or exceeds the scope granted by the resource owner. " \
            "The following scopes were requested, but not granted: #{missing_scopes.to_sentence(locale: :en)}")
    end

    def as_json
      {
        error: :invalid_scope,
        error_description: @message
      }
    end

    def http_status
      400
    end
  end
end

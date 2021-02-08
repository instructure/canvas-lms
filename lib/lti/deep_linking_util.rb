# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# Shared utilities for deep linking responses.
module Lti
  module DeepLinkingUtil
    module_function

    def validate_custom_params(custom)
      custom = JSON.parse(custom) if custom.is_a?(String)
      return nil unless custom.is_a?(Hash)

      custom.
        select{|k, _v| k.is_a?(String) || k.is_a?(Symbol)}.
        select{|_k, v| valid_custom_params_value?(v)}.
        stringify_keys
    rescue JSON::ParserError
      nil
    end

    def valid_custom_params_value?(val)
      case val
      when String, Numeric, true, false, nil
        true
      else
        false
      end
    end
  end
end

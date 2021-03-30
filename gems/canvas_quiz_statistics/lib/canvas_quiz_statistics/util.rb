# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'html_text_helper'

module CanvasQuizStatistics
  module Util
    def self.digest(str)
      Digest::SHA1.hexdigest((str || '').to_s.strip)
    end

    # Converts a hash to use symbol keys.
    #
    # Works on nested hashes, and hashes inside of arrays.
    def self.deep_symbolize_keys(input)
      return input unless input.is_a?(Hash)

      input.inject({}) do |result, (key, value)|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = case value
                    when Hash then deep_symbolize_keys(value)
                    when Array then value.map(&method(:deep_symbolize_keys))
                    else value
                    end

        result[new_key] = new_value
        result
      end
    end

    def self.strip_tags(html)
      ::HtmlTextHelper.strip_tags(html)
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

{
  hi: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          "वाँ"
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          case number
          when 1 then "पहला"
          when 2 then "दूसरा"
          when 3 then "तीसरा"
          when 4 then "चौथा"
          when 6 then "छठा"
          else
            "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
          end
        end
      }
    }
  }
}

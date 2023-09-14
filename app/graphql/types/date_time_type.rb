# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Types::DateTimeType < Types::BaseScalar
  graphql_name "DateTime"
  description "an ISO8601 formatted time string"

  def self.coerce_input(time_str, _)
    if time_str.nil?
      return nil
    end

    Time.zone.iso8601(time_str)
  rescue ArgumentError
    raise GraphQL::CoercionError, "#{time_str.inspect} is not an iso8601 formatted date"
  end

  def self.coerce_result(time, _)
    time.iso8601
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# aws-sdk-dynamo doesn't have any way to hook into its type-marshalling code,
# so i'm going to do it like this :/
module DynamoDBDateSupport
  def format(obj)
    if obj.respond_to?(:iso8601)
      { s: obj.iso8601 }
    else
      super
    end
  end
end

Aws::DynamoDB::AttributeValue::Marshaler.prepend(DynamoDBDateSupport)

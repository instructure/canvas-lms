# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module ActiveModelErrors
  def to_hash(full_messages = false)
    message_method = full_messages ? :full_message : :message
    result = group_by_attribute.transform_values do |errors|
      errors.map do |error|
        {
          attribute: (error.attribute == :base) ? nil : error.attribute,
          message: error.send(message_method) || "invalid",
          type: error.type,
        }
      end
    end

    { errors: result }
  end
end

ActiveModel::Errors.prepend(ActiveModelErrors)

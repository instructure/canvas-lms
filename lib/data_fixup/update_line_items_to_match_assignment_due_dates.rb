# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup
  module UpdateLineItemsToMatchAssignmentDueDates
    def self.run(start_id, end_id)
      ::Lti::LineItem
        .joins(:assignment)
        .select("#{::Lti::LineItem.quoted_table_name}.*", "#{Assignment.quoted_table_name}.due_at")
        .where(id: start_id..end_id)
        .where("#{Assignment.quoted_table_name}.due_at != #{::Lti::LineItem.quoted_table_name}.end_date_time OR #{::Lti::LineItem.quoted_table_name}.end_date_time IS NULL")
        .each do |line_item|
          update_line_item_date(line_item)
        end
    end

    def self.update_line_item_date(line_item)
      line_item.update(end_date_time: line_item.assignment.due_at)
    end
  end
end

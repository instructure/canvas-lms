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

# Extend the query logger to add "SQL" back to the front, like it was in
# rails2, to make it easier to pull out those log lines for analysis.
module AddSQLToLogLines
  def sql(event)
    name = event.payload[:name]
    if name != "SCHEMA"
      event.payload[:name] = "SQL #{name}"
    end
    super
  end
end
ActiveRecord::LogSubscriber.prepend(AddSQLToLogLines)

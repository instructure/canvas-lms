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
#

module Api::V1::CustomGradebookColumn
  include Api::V1::Json

  def custom_gradebook_column_json(column, user, session)
    json = api_json column, user, session, only: %w[id
                                                    title
                                                    position
                                                    teacher_notes
                                                    read_only]
    json[:hidden] = column.hidden?
    json
  end

  def custom_gradebook_column_datum_json(datum, user, session)
    api_json datum, user, session, only: %w[user_id content]
  end
end

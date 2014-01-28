#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::QuizIpFilter
  include Api::V1::Json

  API_ALLOWED_QUIZ_IP_FILTER_OUTPUT_FIELDS = {
    :only => %w[
      name
      account
      filter
    ]
  }

  def quiz_ip_filters_json(filters, context, user, session)
    hash = {}

    hash[:quiz_ip_filters] = filters.map do |filter|
      quiz_ip_filter_json(filter, context, user, session)
    end

    hash
  end

  def quiz_ip_filter_json(filter, context, user, session)
    api_json(filter.with_indifferent_access, user, session, API_ALLOWED_QUIZ_IP_FILTER_OUTPUT_FIELDS)
  end
end

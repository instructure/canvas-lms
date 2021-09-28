# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Api::V1::GradingStandard
  include Api::V1::Json

  def grading_standard_json(grading_standard, user, session)
    api_json(grading_standard, user, session, :only => %w(id title context_type context_id)).tap do |hash|
      hash[:grading_scheme] = grading_standard['data'].map{|a| {name:a[0], value:a[1]}}
    end
  end

end
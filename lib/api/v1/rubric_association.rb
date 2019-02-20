#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Api::V1::RubricAssociation
  include Api::V1::Json

  API_ALLOWED_RUBRIC_ASSOCIATION_OUTPUT_FIELDS = {
    only: %w(
      id
      rubric_id
      association_type
      association_id
      use_for_grading
      summary_data
      purpose
      hide_score_total
      hide_points
      hide_outcome_results
    )
  }.freeze

  def rubric_associations_json(rubric_associations, user, session, opts = {})
    rubric_associations.map { |ra| rubric_association_json(ra, user, session, opts) }
  end

  def rubric_association_json(rubric_association, user, session, _opts = {})
    json_attributes = API_ALLOWED_RUBRIC_ASSOCIATION_OUTPUT_FIELDS
    hash = api_json(rubric_association, user, session, json_attributes)
    hash
  end
end
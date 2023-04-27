# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Api::V1::RubricAssessment
  include Api::V1::Json

  API_ALLOWED_RUBRIC_ASSESSMENT_OUTPUT_FIELDS = {
    only: %w[
      id
      rubric_id
      rubric_association_id
      score
      artifact_type
      artifact_id
      artifact_attempt
      assessment_type
      assessor_id
    ]
  }.freeze

  def rubric_assessments_json(rubric_assessments, user, session, opts = {})
    rubric_assessments.map { |ra| rubric_assessment_json(ra, user, session, opts) }
  end

  def rubric_assessment_json(rubric_assessment, user, session, opts = {})
    json_attributes = API_ALLOWED_RUBRIC_ASSESSMENT_OUTPUT_FIELDS
    hash = api_json(rubric_assessment, user, session, json_attributes)
    hash["data"] = rubric_assessment.data if opts[:style] == "full"
    if opts[:style] == "full" && rubric_assessment.active_rubric_association?
      hash["rubric_association"] = rubric_assessment.rubric_association.as_json["rubric_association"]
      hash["rubric_association"]["hide_points"] = rubric_assessment.rubric_association.hide_points(user)
    end
    hash["comments"] = rubric_assessment.data.pluck(:comments) if opts[:style] == "comments_only"
    hash
  end

  def indexed_rubric_assessment_json(rubric_assessment)
    rubric_assessment.data.to_h do |r|
      [r[:criterion_id], { rating_id: r[:id] }.merge(r.slice(:comments, :points))]
    end
  end

  def full_rubric_assessment_json_for_submissions(rubric_assessment, user, session)
    hash = rubric_assessment_json(rubric_assessment, user, session, { style: "full" })
    assessor = User.find(rubric_assessment.assessor_id)
    hash["assessor_name"] = assessor.name
    hash["assessor_avatar_url"] = assessor.avatar_image_url
    hash
  end
end

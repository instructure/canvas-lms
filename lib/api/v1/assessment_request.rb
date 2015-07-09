#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

module Api::V1::AssessmentRequest
  include Api::V1::Json
  include Api::V1::Submission
  include Api::V1::SubmissionComment

  def assessment_request_json(assessment_request, user, session, includes = Set.new)
    assignment = assessment_request.asset.assignment
    json_attributes = %w(id user_id assessor_id asset_id asset_type workflow_state)
    if assignment.anonymous_peer_reviews? && !assignment.grants_any_right?(user, session, :grade)
      json_attributes.delete('assessor_id')
    end

    hash = api_json(assessment_request, user, session, :only => json_attributes)

    if includes.include?("user")
      hash['user'] = user_display_json(assessment_request.user, @context)
      unless assignment.anonymous_peer_reviews? && !assignment.grants_any_right?(user, session, :grade)
        hash['assessor'] = user_display_json(assessment_request.assessor, @context)
      end
    end

    if includes.include?("submission_comments")
      hash['submission_comments'] = assessment_request.asset.submission_comments.map{ |sc| submission_comment_json(sc, user) }
    end
    hash
  end

  def assessment_requests_json(assessment_requests, user, session, includes = Set.new)
    assessment_requests.map{ |assessment_request| assessment_request_json(assessment_request, user, session, includes) }
  end

end
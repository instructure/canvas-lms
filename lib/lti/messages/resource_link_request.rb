#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::Messages
  class ResourceLinkRequest < JwtMessage
    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      super
      @message = LtiAdvantage::Messages::ResourceLinkRequest.new
    end

    def generate_post_payload
      add_resource_link_request_claims!
      super
    end

    def generate_post_payload_for_assignment(assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
      lti_assignment = Lti::LtiAssignmentCreator.new(assignment).convert
      add_extension('lis_result_sourcedid', lti_assignment.source_id)
      add_extension('lis_outcome_service_url', outcome_service_url)
      add_extension('ims_lis_basic_outcome_url', legacy_outcome_service_url)
      add_extension('outcome_data_values_accepted', lti_assignment.return_types.join(','))
      add_extension('outcome_result_total_score_accepted', true)
      add_extension('outcome_submission_submitted_at_accepted', true)
      add_extension('outcomes_tool_placement_url', lti_turnitin_outcomes_placement_url)
      add_assignment_substitutions!
      generate_post_payload
    end

    def generate_post_payload_for_homework_submission(assignment)
      lti_assignment = Lti::LtiAssignmentCreator.new(assignment).convert
      add_extension('content_return_types', lti_assignment.return_types.join(','))
      add_extension('content_file_extensions', assignment.allowed_extensions&.join(','))
      add_assignment_substitutions!
      generate_post_payload
    end

    private

    def add_resource_link_request_claims!
      @message.resource_link.id = Lti::Asset.opaque_identifier_for(@context)
    end

    def add_assignment_substitutions!
      add_extension('canvas_assignment_id', '$Canvas.assignment.id') if @tool.public?
      add_extension('canvas_assignment_title', '$Canvas.assignment.title')
      add_extension('canvas_assignment_points_possible', '$Canvas.assignment.pointsPossible')
    end
  end
end
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

require 'turnitin_api'
module Turnitin
  class TiiClient < TurnitinApi::OutcomesResponseTransformer

    def initialize(user, assignment, tool, outcomes_response_json)
      lti_params = {
        'user_id' => Lti::Asset.opaque_identifier_for(user),
        'context_id' => Lti::Asset.opaque_identifier_for(assignment.context),
        'context_title' => assignment.context.name,
        'lis_person_contact_email_primary' => user.email
      }

      super(
        tool.consumer_key,
        tool.shared_secret,
        lti_params,
        outcomes_response_json
      )
    end

    def turnitin_data
      {
        similarity_score: originality_data["numeric"]["score"].to_f,
        web_overlap: originality_data["breakdown"]["internet_score"].to_f,
        publication_overlap: originality_data["breakdown"]["publications_score"].to_f,
        student_overlap: originality_data["breakdown"]["submitted_works_score"].to_f,
        state: Turnitin.state_from_similarity_score(originality_data["numeric"]["score"].to_f),
        report_url: originality_report_url,
        status: "scored"
      }
    end

  end
end

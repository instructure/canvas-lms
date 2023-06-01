# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module MicrosoftSync
  class GraphService
    class TeamsEndpoints < EndpointsBase
      TEAM_EXISTS_SPECIAL_CASES = [
        SpecialCase.new(404, result: :not_found)
      ].freeze

      def team_exists?(team_id)
        request(:get, "teams/#{team_id}", special_cases: TEAM_EXISTS_SPECIAL_CASES) != :not_found
      end

      CREATE_FOR_EDUCATION_CLASS_SPECIAL_CASES = [
        SpecialCase.new(
          400,
          /have one or more owners in order to create a Team/i,
          result: MicrosoftSync::Errors::GroupHasNoOwners
        ),
        SpecialCase.new(
          409,
          /group is already provisioned/i,
          result: MicrosoftSync::Errors::TeamAlreadyExists
        )
      ].freeze

      def create_for_education_class(group_id)
        body = {
          "template@odata.bind" =>
            "https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')",
          "group@odata.bind" =>
            "https://graph.microsoft.com/v1.0/groups(#{quote_value(group_id)})"
        }

        # Use special_cases exceptions so they use statsd "expected" counters
        request(:post, "teams", body:, special_cases: CREATE_FOR_EDUCATION_CLASS_SPECIAL_CASES)
      end
    end
  end
end

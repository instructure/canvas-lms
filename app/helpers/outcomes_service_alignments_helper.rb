# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module OutcomesServiceAlignmentsHelper
  include CanvasOutcomesHelper
  OSA_CACHE_EXPIRATION = 60.seconds

  def get_os_aligned_outcomes(context)
    return if context.blank?

    params = { context_uuid: context.uuid, context_id: context.id }

    domain, jwt = extract_domain_jwt(
      context.root_account,
      "outcome_alignments.show",
      **params
    )
    return if domain.nil? || jwt.nil?

    # for uniqueness, scope cache key to account uuid, context uuid and context id
    cache_key = [:os_aligned_outcomes, :account_uuid, context.root_account.uuid, :context_uuid, context.uuid, :context_id, context.id].cache_key

    Rails.cache.fetch(cache_key, expires_in: OSA_CACHE_EXPIRATION) do
      response = CanvasHttp.get(
        build_request_url(protocol, domain, "api/alignments", params),
        {
          "Authorization" => jwt
        }
      )

      raise OSFetchError, "Error retrieving aligned outcomes from Outcomes-Service: #{response.body}" unless /^2/.match?(response.code.to_s)

      resp_body = JSON.parse(response.body, symbolize_names: true)

      # minify response to reduce cache size
      # needs to be updated after OUT-5473 and OUT-5474 are merged
      (resp_body[:outcomes] || []).map { |o| [o[:external_id], []] }.to_h
    end
  end
end

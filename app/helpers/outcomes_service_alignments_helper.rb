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

require "parallel"

module OutcomesServiceAlignmentsHelper
  include CanvasOutcomesHelper
  OSA_CACHE_EXPIRATION = 60.seconds
  THREAD_POOL_SIZE = 4
  PER_PAGE = 25

  def get_os_aligned_outcomes(context)
    return if context.blank?

    params = { context_uuid: context.uuid, context_id: context.id }

    # for uniqueness, scope cache key to account uuid, context uuid and context id
    cache_key = [:os_aligned_outcomes, :account_uuid, context.root_account.uuid, :context_uuid, context.uuid, :context_id, context.id].cache_key

    Rails.cache.fetch(cache_key, expires_in: OSA_CACHE_EXPIRATION) do
      results = make_paginated_request(context:, scope: "outcome_alignments.show", endpoint: "api/alignments", params:)
      results&.reduce({}) { |acc, results_page| acc.merge!(results_page) }
    end
  end

  # filters OS alignments against active outcomes and new quizzes in Canvas to prevent data discrepancies due to sync delays
  def get_active_os_alignments(context)
    os_aligned_outcomes = get_os_aligned_outcomes(context)

    return {} if os_aligned_outcomes.blank?

    active_os_alignments = {}

    active_new_quizes = Assignment
                        .active
                        .where(context:, submission_types: "external_tool")
                        .pluck(:id)
                        .map do |id|
      {
        associated_asset_type: "canvas.assignment.quizzes",
        assocated_asset_id: id.to_s
      }
    end

    active_outcome_ids = ContentTag
                         .not_deleted
                         .learning_outcome_links
                         .where(context:)
                         .pluck(:content_id)
                         .map(&:to_s)

    # remove deleted outcomes and alignments to deleted new quizzes
    os_aligned_outcomes
      .slice(*active_outcome_ids)
      .each do |key, value|
      active_os_alignments.merge!(key => value.filter do |a|
                                           active_new_quizes.include?({
                                                                        associated_asset_type: a[:associated_asset_type],
                                                                        assocated_asset_id: a[:associated_asset_id]
                                                                      })
                                         end)
    end

    # remove outcomes without alignments
    active_os_alignments.reject { |_, val| val.empty? }
  end

  def make_paginated_request(context:, scope:, endpoint:, params:)
    domain, jwt = extract_domain_jwt(
      context.root_account,
      scope,
      **params
    )

    return if domain.nil? || jwt.nil?

    # get first page
    first_page_results, total_pages = get_paginated_results(context:, domain:, endpoint:, jwt:, params:).values_at(:results, :total_pages)

    # get the rest of the pages concurrently
    if total_pages > 1
      more_page_results = Parallel.map((2..total_pages).to_a, in_threads: [total_pages - 1, THREAD_POOL_SIZE].min) do |page|
        get_paginated_results(context:, domain:, endpoint:, jwt:, params:, page:).values_at(:results)
      end
    end

    # first page results come as hash so we cannot concat but we can <<
    # more page results come as array of arrays from Parallel so we need to flatten before concat
    ([] << first_page_results).concat((more_page_results || []).flatten)
  end

  def get_paginated_results(context:, domain:, endpoint:, jwt:, params:, page: 1, per_page: PER_PAGE)
    retry_count = 0
    pagination_params = { page:, per_page: }
    params = params.merge(pagination_params)

    begin
      response = CanvasHttp.get(
        build_request_url(protocol, domain, endpoint, params), { "Authorization" => jwt }
      )
    rescue
      retry_count += 1
      retry if retry_count < MAX_RETRIES
      raise OSFetchError, "Failed to fetch results for context #{context.id} #{params}"
    end

    if /^2/.match?(response.code.to_s)
      raw_total_pages = response.header["Total-Pages"].to_i
      total_pages = raw_total_pages.positive? ? raw_total_pages : 1

      begin
        resp_body = JSON.parse(response.body, symbolize_names: true)

        # convert results to hash with outcome ids as keys and alignments as values
        results = (resp_body[:outcomes] || []).to_h { |o| [o[:external_id], o[:alignments] || []] }

        { results:, total_pages: }
      rescue
        raise OSFetchError, "Error parsing JSON from the Outcomes Service: #{response.body}"
      end
    else
      raise OSFetchError, "Error retrieving outcome alignments from the Outcomes Service: #{response.body}"
    end
  end
end

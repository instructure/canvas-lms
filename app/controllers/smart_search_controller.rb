# frozen_string_literal: true

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

class SmartSearchController < ApplicationController
  before_action :require_user

  # TODO: Other ways of tuning results?
  MIN_DISTANCE = 0.70

  def index
    return render_unauthorized_action unless OpenAi.smart_search_available?(@domain_root_account)
    return render json: { error: "missing 'q' param" }, status: :bad_request unless params.key?(:q)

    # TODO: Add feature flag check / other "authorized_action" check here.
    if true # rubocop:disable Lint/LiteralAsCondition
      response = {
        results: []
      }

      if params[:q].present?
        embedding = OpenAi.generate_embedding(params[:q])[0]

        # Prototype query using "neighbor". Embedding is now on join table so manual SQL for now
        # wiki_pages = WikiPage.nearest_neighbors(:embedding, embedding, distance: "inner_product")
        # response[:results].concat( wiki_pages.select { |x| x.neighbor_distance >= MIN_DISTANCE }.first(MAX_RESULT))

        # Wiki Pages
        # TODO: Make this more ActiveRecord(y) while still enforcing the right visibility
        # TODO: Enforce enrollment types
        # TODO: Prevent multiple inner-product calls, if possible
        # TODO: Prevent duplicates after chunking embeddings is implemented
        # TODO: Paginate and remove the hardcoded limit (ADV-23)
        sql = <<-SQL.squish
                SELECT wp.*, (wpe.embedding <=> ?) AS distance
                FROM "wiki_pages" wp
                INNER JOIN "enrollments" AS e
                    ON wp.context_type = 'Course'
                    AND wp.context_id = e.course_id
                INNER JOIN "enrollment_states" AS es
                    ON e.id = es.enrollment_id
                INNER JOIN "wiki_page_embeddings" AS wpe
                    ON wp.id = wpe.wiki_page_id
                WHERE
                    e.user_id = ?
                    AND e.workflow_state <> 'deleted'
                    AND es.restricted_access = FALSE
                    AND es.state IN ('active', 'invited', 'pending_invited', 'pending_active')
                    AND e.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'StudentViewEnrollment')
                ORDER BY distance asc
                LIMIT 25
        SQL
        wiki_pages = WikiPage.find_by_sql([sql, embedding.to_s, @current_user.id])
        response[:results].concat(wiki_pages)
      end

      render json: response
    end
  end

  def show
    render_unauthorized_action unless OpenAi.smart_search_available?(@domain_root_account)
    # TODO: Add state required for new page render
  end
end

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
        embedding = OpenAi.generate_embedding(params[:q])

        # Prototype query using "neighbor". Embedding is now on join table so manual SQL for now
        # wiki_pages = WikiPage.nearest_neighbors(:embedding, embedding, distance: "inner_product")
        # response[:results].concat( wiki_pages.select { |x| x.neighbor_distance >= MIN_DISTANCE }.first(MAX_RESULT))

        # Wiki Pages
        # TODO: Enforce enrollment types
        scope = WikiPage
                .select(WikiPage.send(:sanitize_sql, ["wiki_pages.*, MIN(wpe.embedding #{quoted_operator_name("<=>")} ?) AS distance", embedding.to_s]))
                .joins("INNER JOIN #{Enrollment.quoted_table_name} e ON wiki_pages.context_type = 'Course' AND wiki_pages.context_id = e.course_id")
                .joins("INNER JOIN #{EnrollmentState.quoted_table_name} es ON e.id = es.enrollment_id")
                .joins("INNER JOIN #{WikiPageEmbedding.quoted_table_name} wpe ON wiki_pages.id = wpe.wiki_page_id")
                .where(e: {
                         user_id: @current_user,
                         type: %w[TeacherEnrollment TaEnrollment DesignerEnrollment StudentViewEnrollment]
                       },
                       es: {
                         restricted_access: false,
                         state: %w[active invited pending_invited pending_active]
                       })
                .where.not(e: { workflow_state: "deleted" })
                .group("wiki_pages.id")
                .order("distance ASC")
        wiki_pages = Api.paginate(scope, self, smart_search_query_url)
        response[:results].concat(wiki_pages)
      end

      render json: response
    end
  end

  def show
    render_unauthorized_action unless OpenAi.smart_search_available?(@domain_root_account)
    # TODO: Add state required for new page render
  end

  protected

  def quoted_operator_name(operator)
    "operator(#{PG::Connection.quote_ident(ActiveRecord::Base.connection.extension("vector").schema)}.#{operator})"
  end
end

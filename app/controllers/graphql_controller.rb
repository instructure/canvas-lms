# frozen_string_literal: true

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
#

# pre-build the graphql schema (which is expensive and slow) so that the first
# request is not slow and terrible
CanvasSchema.graphql_definition

class GraphQLController < ApplicationController
  include Api::V1

  before_action :require_user, if: :require_auth?
  before_action :require_inst_access_token_auth, only: :subgraph_execute, unless: :sdl_query?
  # This makes sure that the liveEvents context is set up for graphql requests
  before_action :get_context

  # This action is for use only with the federated API Gateway. See
  # `app/graphql/README.md` for details.
  def subgraph_execute
    result = execute_on(CanvasSchema.for_federation)
    render json: result
  end

  def execute
    result = execute_on(CanvasSchema)
    prep_page_view_for_submit
    prep_page_view_for_create_discussion_entry
    render json: result
  end

  def graphiql
    @page_title = "GraphiQL"
    render :graphiql, layout: "bare"
  end

  private

  def execute_on(schema)
    query = params[:query]
    variables = params[:variables] || {}
    context = {
      current_user: @current_user,
      real_current_user: @real_current_user,
      session:,
      request:,
      domain_root_account: @domain_root_account,
      access_token: @access_token,
      in_app: in_app?,
      deleted_models: {},
      request_id: (Thread.current[:context] || {})[:request_id],
      tracers: [
        Tracers::DatadogTracer.new(
          request.headers["GraphQL-Metrics"] == "true",
          request.host_with_port.sub(":", "_")
        )
      ]
    }

    Timeout.timeout(1.minute) do
      schema.execute(query, variables:, context:)
    end
  end

  def require_auth?
    if action_name == "execute"
      return !::Account.site_admin.feature_enabled?(:disable_graphql_authentication)
    end

    if !Rails.env.production? && action_name == "subgraph_execute" && sdl_query?
      return false
    end

    true
  end

  def sdl_query?
    query = (params[:query] || "").strip
    return false unless query.starts_with?("query") || query.starts_with?("{")

    query = query[/{.*/] # slice off leading "query" keyword and/or query name, if any
    query.gsub!(/\s+/, "") # strip all whitespace
    query == "{_service{sdl}}"
  end

  def require_inst_access_token_auth
    unless @authenticated_with_inst_access_token
      render(
        json: { errors: [{ message: "InstAccess token auth required" }] },
        status: :unauthorized
      )
    end
  end

  def prep_page_view_for_submit
    return unless params[:operationName] == "CreateSubmission"

    assignment = ::Assignment.active.find(params[:variables][:assignmentLid])
    get_context
    log_asset_access(assignment, "assignments", nil, "participate")
  end

  def prep_page_view_for_create_discussion_entry
    return unless params[:operationName] == "CreateDiscussionEntry"

    topic = DiscussionTopic.find(params[:variables][:discussionTopicId])
    get_context
    log_asset_access(topic, "topics", "topics", "participate")
  end
end

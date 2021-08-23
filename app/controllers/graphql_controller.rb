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

  # This action is for use only with the federated API Gateway. See
  # `app/graphql/README.md` for details.
  def subgraph_execute
    result = execute_on(CanvasSchema.for_federation, "subgraph")
    render json: result
  end

  def execute
    result = execute_on(CanvasSchema, "original")
    render json: result
  end

  def graphiql
    @page_title = "GraphiQL"
    render :graphiql, layout: 'bare'
  end

  private

  def execute_on(schema, interface_name)
    query = params[:query]
    variables = params[:variables] || {}
    context = {
      current_user: @current_user,
      real_current_user: @real_current_user,
      session: session,
      request: request,
      domain_root_account: @domain_root_account,
      access_token: @access_token,
      in_app: in_app?,
      deleted_models: {},
      request_id: (Thread.current[:context] || {})[:request_id],
      tracers: [
        Tracers::DatadogTracer.new(
          request.headers["GraphQL-Metrics"] == "true",
          {
            domain: request.host_with_port.sub(':', '_'),
            interface: interface_name
          }
        )
      ]
    }

    overall_timeout = Setting.get('graphql_overall_timeout', '60').to_i.seconds
    Timeout.timeout(overall_timeout) do
      schema.execute(query, variables: variables, context: context)
    end
  end

  def require_auth?
    if action_name == 'execute'
      return !::Account.site_admin.feature_enabled?(:disable_graphql_authentication)
    end

    if action_name == 'subgraph_execute' && sdl_query?
      return false
    end

    true
  end

  def sdl_query?
    query = (params[:query] || '').strip
    return false unless query.starts_with?('query') || query.starts_with?('{')
    query = query[/{.*/] # slice off leading "query" keyword and/or query name, if any
    query.gsub!(/\s+/, '') # strip all whitespace
    query == '{_service{sdl}}'
  end

  def require_inst_access_token_auth
    unless @authenticated_with_inst_access_token
      render(
        json: {errors: [{message: "InstAccess token auth required"}]},
        status: 401
      )
    end
  end
end

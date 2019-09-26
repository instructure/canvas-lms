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

  before_action :require_user, except: :execute

  def execute
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
      request_id: (Thread.current[:context] || {})[:request_id],
      tracers: [
        Tracers::DatadogTracer.new(
          request.host_with_port.sub(':', '_'),
          request.headers["GraphQL-Metrics"] == "true"
        )
      ]
    }
    result = nil

    overall_timeout = Setting.get('graphql_overall_timeout', '300').to_i.seconds
    Timeout.timeout(overall_timeout) do
      result = CanvasSchema.execute(query, variables: variables, context: context)
    end

    render json: result
  end

  def graphiql
    @page_title = "GraphiQL"
    render :graphiql, layout: 'bare'
  end
end

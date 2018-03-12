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

class GraphQLController < ApplicationController
  include Api::V1

  before_action :require_user, except: :execute


  def execute
    query = params[:query]
    variables = params[:variables] || {}
    tracers = if request.headers["GraphQL-Metrics"] == "true"
                domain = request.host_with_port.sub(':', '_')
                [Tracers::DatadogTracer.new(domain)]
              else
                []
              end
    context = {
      current_user: @current_user,
      session: session,
      request: request,
      tracers: tracers
    }
    result = nil

    ActiveRecord::Base.transaction do
      timeout = Integer(Setting.get('graphql_statement_timeout', '60_000'))
      ActiveRecord::Base.connection.execute "SET statement_timeout = #{timeout}"

      result = CanvasSchema.execute(query, variables: variables, context: context)
    end

    render json: result
  end

  def graphiql
    if Rails.env.production? &&
        !::Account.site_admin.grants_right?(@current_user, session, :read_as_admin)
       render plain: "unauthorized", status: :unauthorized
    else
      render :graphiql, layout: 'bare'
    end
  end
end

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

class GraphQLController < ApplicationController
  include Api::V1

  before_action :require_user, if: :require_auth?
  # This makes sure that the liveEvents context is set up for graphql requests
  before_action :get_context

  def execute
    result = execute_on(CanvasSchema)
    prep_page_view_for_submit
    prep_page_view_for_create_discussion_entry

    # generic errors like exceed complexity are on root level of result
    graphql_errors = result["errors"]
    # query specific business logic errors (e.g. permission required) are nested in the data hash
    query_errors = result.to_h["data"]&.values&.map { |res| (res.is_a?(Hash) && res["errors"].present?) ? res["errors"] : "" }&.reject(&:blank?)

    any_error_occured = graphql_errors.present? || query_errors.present?
    RequestContext::Generator.add_meta_header("ge", any_error_occured ? "f" : "t")
    if any_error_occured
      disable_page_views
      Rails.logger.info "There are GraphQL errors: #{safe_to_json({ graphql_errors:, query_errors: }.compact)}"
      if graphql_errors.present? && graphql_errors.is_a?(Array)
        max_complexity_error = graphql_errors.find { |e| e.is_a?(Hash) && e["message"].to_s.include?("exceeds max complexity") }
        log_exceed_complexity_error(max_complexity_error["message"].to_s) if max_complexity_error.present?
      end
    end

    render json: result
  end

  def graphiql
    @page_title = "GraphiQL"
    render :graphiql, layout: "bare"
  end

  def get_context # rubocop:disable Naming/AccessorMethodName
    case subject&.pick(:context_type, :context_id)
    in nil
      return
    in ["Course", id]
      params[:course_id] = id
    in ["Group", id]
      params[:group_id] = id
    in [context_type, _]
      raise "Can not handle #{context_type} in GraphQL context"
    end

    super
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

    true
  end

  def sdl_query?
    query = (params[:query] || "").strip
    return false unless query.starts_with?("query") || query.starts_with?("{")

    query = query[/{.*/] # slice off leading "query" keyword and/or query name, if any
    query.gsub!(/\s+/, "") # strip all whitespace
    query == "{_service{sdl}}"
  end

  def prep_page_view_for_submit
    return unless params[:operationName] == "CreateSubmission"

    assignment = ::Assignment.active.find(params[:variables][:assignmentLid])
    log_asset_access(assignment, "assignments", nil, "participate")
  end

  def prep_page_view_for_create_discussion_entry
    return unless params[:operationName] == "CreateDiscussionEntry"

    topic = DiscussionTopic.find(params[:variables][:discussionTopicId])
    log_asset_access(topic, "topics", "topics", "participate")
  end

  def subject
    case params[:operationName]
    when "CreateSubmission"
      id = params[:variables][:assignmentLid]
      ::Assignment.active.where(id:)
    when "CreateDiscussionEntry"
      id = params[:variables][:discussionTopicId]
      ::DiscussionTopic.where(id:)
    end
  end

  def safe_to_json(obj)
    obj.to_json
  rescue
    obj
  end

  def log_exceed_complexity_error(err_msg)
    tags = { operation_name: }
    InstStatsd::Statsd.distributed_increment("graphql.errors.exceeds_max_complexity.count", tags:)
    InstStatsd::Statsd.gauge("graphql.errors.exceeds_max_complexity.compexity", err_msg[/complexity of (\d+),/, 1]&.to_i, tags:)
  end

  def operation_name
    document = GraphQL.parse(params[:query])
    document&.definitions&.find { |d| d.is_a?(GraphQL::Language::Nodes::OperationDefinition) }&.name
  rescue GraphQL::ParseError
    "unknown"
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# @API Users
#
#
# @model PageView
#     {
#       "id": "PageView",
#       "description": "The record of a user page view access in Canvas",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "A UUID representing the page view.  This is also the unique request id",
#           "example": "3e246700-e305-0130-51de-02e33aa501ef",
#           "type": "string",
#           "format": "uuid"
#         },
#         "app_name": {
#           "description": "If the request is from an API request, the app that generated the access token",
#           "example": "Canvas for iOS",
#           "type": "string"
#         },
#         "url": {
#           "description": "The URL requested",
#           "example": "https://canvas.instructure.com/conversations",
#           "type": "string"
#         },
#         "context_type": {
#           "description": "The type of context for the request",
#           "example": "Course",
#           "type": "string"
#         },
#         "asset_type": {
#           "description": "The type of asset in the context for the request, if any",
#           "example": "Discussion",
#           "type": "string"
#         },
#         "controller": {
#           "description": "The rails controller that handled the request",
#           "example": "discussions",
#           "type": "string"
#         },
#         "action": {
#           "description": "The rails action that handled the request",
#           "example": "index",
#           "type": "string"
#         },
#         "contributed": {
#           "description": "This field is deprecated, and will always be false",
#           "example": "false",
#           "type": "boolean"
#         },
#         "interaction_seconds": {
#           "description": "An approximation of how long the user spent on the page, in seconds",
#           "example": "7.21",
#           "type": "number"
#         },
#         "created_at": {
#           "description": "When the request was made",
#           "example": "2013-10-01T19:49:47Z",
#           "type": "datetime",
#           "format": "iso8601"
#         },
#         "user_request": {
#           "description": "A flag indicating whether the request was user-initiated, or automatic (such as an AJAX call)",
#           "example": "true",
#           "type": "boolean"
#         },
#         "render_time": {
#           "description": "How long the response took to render, in seconds",
#           "example": "0.369",
#           "type": "number"
#         },
#         "user_agent": {
#           "description": "The user-agent of the browser or program that made the request",
#           "example": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1",
#           "type": "string"
#         },
#         "participated": {
#           "description": "True if the request counted as participating, such as submitting homework",
#           "example": "false",
#           "type": "boolean"
#         },
#         "http_method": {
#           "description": "The HTTP method such as GET or POST",
#           "example": "GET",
#           "type": "string"
#         },
#         "remote_ip": {
#           "description": "The origin IP address of the request",
#           "example": "173.194.46.71",
#           "type": "string"
#         },
#         "links": {
#           "description": "The page view links to define the relationships",
#           "$ref": "PageViewLinks",
#           "example": {"user": 1234, "account": 1234}
#         }
#       }
#     }
#
# @model PageViewLinks
#   {
#     "id": "PageViewLinks",
#     "description": "The links of a page view access in Canvas",
#     "properties": {
#        "user": {
#          "description": "The ID of the user for this page view",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#        "context": {
#          "description": "The ID of the context for the request (course id if context_type is Course, etc)",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#        "asset": {
#          "description": "The ID of the asset for the request, if any",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#        "real_user": {
#          "description": "The ID of the actual user who made this request, if the request was made by a user who was masquerading",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#         "account": {
#           "description": "The ID of the account context for this page view",
#           "example": "1234",
#           "type": "integer",
#           "format": "int64"
#        }
#     }
#   }
#
# @model AsyncApiErrorResponse
#     {
#       "id": "AsyncApiErrorResponse",
#       "description": "Error response structure returned by the API when validation or processing failures occur",
#       "properties": {
#          "errors": {
#            "description": "Array of error messages describing what went wrong with the request",
#            "example": ["start_date and end_date must be the first day of the month", "end_date must be after start_date", "end_date cannot be in a future month", "The requested data cannot be older than %d months"],
#            "type": "array",
#            "items": {
#              "type": "string"
#            }
#          }
#       }
#     }
#
# @model AsyncQueryResponse
#     {
#       "id": "AsyncQueryResponse",
#       "description": "Response returned when successfully initiating a page views query",
#       "required": ["poll_url"],
#       "properties": {
#         "poll_url": {
#           "description": "URL endpoint to poll for query status updates",
#           "example": "/api/v1/users/123/page_views/query/550e8400-e29b-41d4-a716-446655440000",
#           "type": "string",
#           "format": "uri"
#         }
#       }
#     }
#
# @model AsyncQueryStatusResponse
#     {
#       "id": "AsyncQueryStatusResponse",
#       "description": "Response containing the current status of a page views query",
#       "required": ["query_id", "status", "format"],
#       "properties": {
#         "query_id": {
#           "description": "The UUID of the query being polled",
#           "example": "550e8400-e29b-41d4-a716-446655440000",
#           "type": "string",
#           "format": "uuid"
#         },
#         "status": {
#           "description": "Current processing status of the query",
#           "example": "finished",
#           "type": "string",
#           "enum": ["queued", "processing", "finished", "failed"]
#         },
#         "format": {
#           "description": "The format that results will be returned in",
#           "example": "csv",
#           "type": "string",
#           "enum": ["csv", "json"]
#         },
#         "results_url": {
#           "description": "URL to retrieve query results. Only present when status is 'finished'",
#           "example": "/api/v1/users/123/page_views/query/550e8400-e29b-41d4-a716-446655440000/results",
#           "type": "string",
#           "format": "uri"
#         }
#       }
#     }
#
# @model AsyncQueryResultsResponse
#     {
#       "id": "AsyncQueryResultsResponse",
#       "description": "File download response containing page views query results",
#       "properties": {
#         "content": {
#           "description": "The query results data in the requested format (CSV or JSON)",
#           "type": "string",
#           "format": "binary"
#         },
#         "filename": {
#           "description": "Suggested filename for the downloaded results",
#           "example": "550e8400-e29b-41d4-a716-446655440000.csv",
#           "type": "string"
#         },
#         "content_type": {
#           "description": "MIME type of the response content",
#           "example": "text/csv",
#           "type": "string",
#           "enum": ["text/csv", "application/jsonl"]
#         },
#         "content_encoding": {
#           "description": "Content encoding if the response is compressed",
#           "example": "gzip",
#           "type": "string"
#         }
#       }
#     }

class PageViewsController < ApplicationController
  before_action :require_user, only: [:index]

  include Api::V1::PageView

  # @API List user page views
  # Return a paginated list of the user's page view history in json format,
  # similar to the available CSV download. Page views are returned in
  # descending order, newest to oldest.
  #
  # **Disclaimer**: The data is a best effort attempt, and is not guaranteed
  # to be complete or wholly accurate. This data is meant to be used for
  # rollups and analysis in the aggregate, not in isolation for auditing,
  # or other high-stakes analysis involving examining single users or
  # small samples. Page Views data is generated from the Canvas logs files,
  # not a transactional database, there are many places along the way
  # data can be lost and/or duplicated (though uncommon). Additionally,
  # given the size of this data, our processes ensure that errors can be
  # rectified at any point in time, with corrections integrated as soon as
  # they are identified and processed.
  #
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want page views.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want page views.
  #
  # @returns [PageView]
  def index
    @user = api_find(User, params[:user_id])
    return unless authorized_action(@user, @current_user, :view_statistics)

    date_options = {}
    url_options = { user_id: @user }
    if (start_time = CanvasTime.try_parse(params[:start_time]))
      date_options[:oldest] = start_time
      url_options[:start_time] = params[:start_time]
      if start_time > Time.now.utc
        return respond_to do |format|
          format.json { render json: { error: "start_time cannot be in the future" }, status: :bad_request }
          format.any { render plain: t("start_time cannot be in the future"), status: :bad_request }
        end
      end
    end
    if (end_time = CanvasTime.try_parse(params[:end_time]))
      date_options[:newest] = end_time
      url_options[:end_time] = params[:end_time]
    end
    if start_time && end_time && end_time < start_time
      return respond_to do |format|
        format.json { render json: { error: t("end_time must be after start_time") }, status: :bad_request }
        format.any { render plain: t("end_time must be after start_time"), status: :bad_request }
      end
    end

    date_options[:viewer] = @current_user

    respond_to do |format|
      format.json do
        page_views = @user.page_views(date_options)
        url = api_v1_user_page_views_url(url_options)
        @page_views = Api.paginate(page_views, self, url, total_entries: nil)
        render json: page_views_json(@page_views, @current_user, session)
      end
      format.csv do
        cancel_cache_buster

        csv = PageView::CSVReport.new(@user, @current_user, date_options).generate

        options = {
          type: "text/csv",
          filename: t(:download_filename,
                      "Pageviews For %{user}",
                      user: @user.name.to_s.tr(" ", "_")) + ".csv",
          disposition: "attachment"
        }
        send_data(csv, options)
      end
    end
  rescue PageView::Pv4Client::Pv4BadRequest => e
    Canvas::Errors.capture_exception(:pv4, e, :warn)
    render json: { error: t("Page Views received an invalid or malformed request.") }, status: :bad_request
  rescue PageView::Pv4Client::Pv4NotFound, PageView::Pv4Client::Pv4Unauthorized => e
    Canvas::Errors.capture_exception(:pv4, e, :warn)
    render json: { error: t("Page Views resource not found.") }, status: :not_found
  rescue PageView::Pv4Client::Pv4TooManyRequests => e
    Canvas::Errors.capture_exception(:pv4, e, :warn)
    render json: { error: t("Page Views rate limit exceeded. Please wait and try again.") }, status: :too_many_requests
  rescue PageView::Pv4Client::Pv4EmptyResponse => e
    Canvas::Errors.capture_exception(:pv4, e, :warn)
    render json: { error: t("Page Views data is not available at this time.") }, status: :service_unavailable
  rescue PageView::Pv4Client::Pv4Timeout => e
    Canvas::Errors.capture_exception(:pv4, e, :warn)
    render json: { error: t("Page Views service is temporarily unavailable.") }, status: :bad_gateway
  end

  def update
    render json: { ok: true }
    # page view update happens in log_page_view after_action
  end

  # @API BETA - Initiate page views query
  # Initiates an asynchronous query for user page views data within a specified date range.
  # This method enqueues a background job to process the page views query and returns
  # a polling URL that can be used to check the query status and retrieve results when ready.
  #
  # As this is a beta endpoint, it is subject to change or removal at any time without the standard notice periods outlined in the API policy.
  #
  # @argument start_date [String]
  #   The start date for the page views query in YYYY-MM-DD format. Must be the first day of a month.
  #
  # @argument end_date [String]
  #   The end date for the page views query in YYYY-MM-DD format. Must be the first day of a month and after start_date.
  #
  # @argument results_format [String]
  #   The desired format for the query results. Supported formats: "csv", "jsonl"
  #
  # @returns AsyncQueryResponse
  # @returns AsyncApiErrorResponse
  #
  # @example_request
  #   curl https://<canvas>/api/v1/users/:user_id/page_views/query \
  #     -X POST \
  #     -H 'Authorization: Bearer <token>' \
  #     -H 'Content-Type: application/json' \
  #     -d '{
  #       "start_date": "2023-01-01",
  #       "end_date": "2023-02-01",
  #       "results_format": "csv"
  #     }'
  #
  # @example_response 201
  #   {
  #     "poll_url": "/api/v1/users/123/page_views/query/550e8400-e29b-41d4-a716-446655440000"
  #   }
  #
  # @example_response 400
  #   {
  #     "error": "Page Views received an invalid or malformed request."
  #   }
  #
  # @example_response 429
  #   {
  #     "error": "Page Views rate limit exceeded. Please wait and try again."
  #   }
  def query
    user_id, start_date, end_date, results_format = params.require(%i[user_id start_date end_date results_format])
    @user = api_find(User, user_id)
    return unless authorized_action(@user, @current_user, :view_statistics)

    query_id = pv5_enqueue_service.call(
      start_date,
      end_date,
      @user,
      results_format
    )
    poll_url = api_v1_page_views_poll_query_status_path(query_id:)
    render json: { poll_url: }, status: :created
  rescue ActionController::ParameterMissing => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: t("Parameter %{param} is missing.", param: e.param) }, status: :bad_request
  rescue ArgumentError => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: t("Page Views received an invalid or malformed request.") }, status: :bad_request
  rescue PageViews::Common::TooManyRequestsError => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: t("Page Views rate limit exceeded. Please wait and try again.") }, status: :too_many_requests
  end

  # @API BETA - Poll query status
  # Checks the status of a previously initiated page views query. Returns the current
  # processing status and provides a result URL when the query is complete.
  #
  # As this is a beta endpoint, it is subject to change or removal at any time without the standard notice periods outlined in the API policy.
  #
  # @argument query_id [String]
  #   The UUID of the query to check status for
  #
  # @returns AsyncQueryStatusResponse
  # @returns AsyncApiErrorResponse
  #
  # @example_request
  #   curl https://<canvas>/api/v1/users/:user_id/page_views/query/:query_id \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response 200
  #   {
  #     "query_id": "550e8400-e29b-41d4-a716-446655440000",
  #     "status": "finished",
  #     "format": "csv",
  #     "results_url": "/api/v1/users/123/page_views/query/550e8400-e29b-41d4-a716-446655440000/results"
  #   }
  #
  # @example_response 200
  #   {
  #     "query_id": "550e8400-e29b-41d4-a716-446655440000",
  #     "status": "processing",
  #     "format": "csv",
  #     "results_url": null
  #   }
  #
  # @example_response 400
  #   {
  #     "error": "Invalid query ID"
  #   }
  #
  # @example_response 404
  #   {
  #     "error": "The query was not found."
  #   }
  def poll_query
    validate_query_id!
    result = pv5_poll_service.call(params[:query_id])
    results_url = api_v1_page_views_get_query_results_path(params[:user_id], params[:query_id]) if result.status == :finished
    render json: { query_id: params[:query_id], status: result.status, format: result.format, results_url: }
  rescue PageViews::Common::NotFoundError => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: t("The query was not found.") }, status: :not_found
  rescue PageViews::Common::InvalidRequestError, ArgumentError => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: e.message }, status: :bad_request
  end

  # @API BETA - Get query results
  # Retrieves the results of a completed page views query. Returns the data in the
  # format specified when the query was initiated (CSV or JSON). The response may
  # be compressed with gzip encoding.
  #
  # As this is a beta endpoint, it is subject to change or removal at any time without the standard notice periods outlined in the API policy.
  #
  # @argument query_id [String]
  #   The UUID of the completed query to retrieve results for
  #
  # @returns QueryResultsResponse
  # @returns AsyncApiErrorResponse
  #
  # @example_request
  #   curl https://<canvas>/api/v1/users/:user_id/page_views/query/:query_id/results \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response 200
  #   # Returns file download with appropriate Content-Type header
  #   # Content-Type: text/csv (for CSV format)
  #   # Content-Type: application/jsonl (for JSON lines format)
  #   # Content-Encoding: gzip (if compressed)
  #   # Content-Disposition: attachment; filename="550e8400-e29b-41d4-a716-446655440000.csv"
  #
  # @example_response 204
  #   # No Content - Query completed but produced no results
  #
  # @example_response 400
  #   {
  #     "error": "Query results are not in a valid state for download"
  #   }
  #
  # @example_response 404
  #   {
  #     "error": "The result for query was not found."
  #   }
  #
  # @example_response 500
  #   {
  #     "error": "An unexpected error occurred."
  #   }
  def query_results
    validate_query_id!
    result = pv5_fetch_result_service.call(params[:query_id])
    response.set_header("Content-Encoding", "gzip") if result.compressed?
    send_data(
      result.content,
      filename: result.filename,
      type: PageViews::Common::CONTENT_TYPE_MAPPINGS.key(result.format),
      disposition: "attachment"
    )
  rescue PageViews::Common::InvalidResultError => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: e.message }, status: :bad_request
  rescue PageViews::Common::NotFoundError => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: t("The result for query was not found.") }, status: :not_found
  rescue PageViews::Common::NoContentError => e
    Canvas::Errors.capture_exception(:pv5, e, :info)
    head :no_content
  rescue => e
    Canvas::Errors.capture_exception(:pv5, e, :warn)
    render json: { error: t("An unexpected error occurred.") }, status: :internal_server_error
  end

  private

  def pv5_enqueue_service
    PageViews::EnqueueQueryService.new(PageViews::Configuration.new, requestor_user: @current_user)
  end

  def pv5_poll_service
    PageViews::PollQueryService.new(PageViews::Configuration.new)
  end

  def pv5_fetch_result_service
    PageViews::FetchResultService.new(PageViews::Configuration.new)
  end

  def validate_query_id!
    query_id = params[:query_id]
    raise ArgumentError, "Invalid query ID" unless uuid?(query_id)
  end

  def uuid?(string)
    !!(string =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/)
  end
end

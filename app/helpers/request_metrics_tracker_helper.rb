# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
# app/controllers/concerns/request_metric_tracker.rb

module RequestMetricsTrackerHelper
  private

  # Wraps each controller action in a timing block and sends metrics to Datadog.
  #
  # About status codes:
  # - Inside a controller around_action, `response.status` is not yet reliable
  #   when exceptions are raised. It will almost always show `200`.
  # - For failures, we therefore do not rely on Rails' response status.
  #   Instead, we tag the request as "error" whenever an exception is caught.
  #
  # Errors this catches:
  # - Any Ruby exception raised inside controller actions, filters, or views
  #   (e.g., NoMethodError, ArgumentError, ActiveRecord::RecordNotFound if not rescued).
  # - Exceptions from libraries (e.g., Faraday::TimeoutError, PG::Error)
  #   if they bubble up through the controller.
  #
  # Errors this does not catch:
  # - Low-level request timeouts from the web server (Puma, Passenger, Nginx) —
  #   the process is killed before Ruby can rescue.
  # - Exceptions rescued by other Rails layers (e.g., custom rescue_from handlers)
  #   before they reach this block.
  #
  def track_request_timing
    Utils::InstStatsdUtils::Timing.track("canvas.controller.request_time") do |meta|
      yield # Run the controller action
      meta.tags = build_tags(:success)
    rescue => e
      # Mark as error if any Ruby exception is raised
      meta.tags = build_tags(:error, e)
      raise
    ensure
      # Ensure metrics are sent regardless of success or failure
      meta.send_stats = should_send_metrics?
    end
  end

  # Override this in your controller if you want to skip sending metrics
  def should_send_metrics?
    true
  end

  # Builds tags for Datadog metrics.
  #
  # Includes basic request info plus error type if available.
  #
  # Override this method in your controller (or subclass) to
  # add more contextual tags — for example:
  # - current user ID
  # - account ID
  # - GraphQL operation name
  # - feature flags
  #
  def build_tags(status, exception = nil)
    tags = base_metric_tags.merge(status: status.to_s)
    tags[:error_type] = exception.class.name if exception
    tags
  end

  def base_metric_tags
    {
      controller: controller_name,
      action: action_name,
      method: request.method.downcase
    }
  end
end

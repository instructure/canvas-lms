# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module GradebookRequestMetricsTrackerHelper
  include RequestMetricsTrackerHelper

  def should_send_metrics?
    request.referer&.include?("gradebook") && request.headers.fetch("HTTP_CORRELATION_ID", nil).present?
  end

  def base_metric_tags
    super.merge({
                  domain: request.host_with_port.sub(":", "_"),
                  referer: sanitize_referer_for_metrics(request.referer),
                  correlation_id: request.headers.fetch("HTTP_CORRELATION_ID", nil)
                })
  end

  private

  def sanitize_referer_for_metrics(referer_url)
    return nil unless referer_url

    uri = URI.parse(referer_url)
    uri.path
  rescue URI::InvalidURIError
    nil
  end
end

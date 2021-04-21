# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DatadogRumHelper
  # Call `request_datadog_rum_js` in a controller action to ensure that the
  # rendered page will include the Datadog RUM JavaScript and bypass the random
  # check. It will NOT be included if the sample rate is set to 0.0, which
  # effectively disables the feature.
  def request_datadog_rum_js
    @datadog_rum_config_requested = true
  end

  # Call `opt_in_datadog_rum_js` in a controller action to allow the next page
  # render to _potentially_ include the Datadog RUM JavaScript, pending the
  # random check. When a controller action has not opted in or requested the
  # rum, it will not be included in the page render. It will NOT be included if
  # the sample rate is set to 0.0, which effectively disables the feature.
  def opt_in_datadog_rum_js
    @datadog_rum_config_opted_in = true
  end

  # Call `include_datadog_rum_js?` to check whether or not the Datadog RUM
  # JavaScript will be included in the next page render. A random check will be
  # performed the first time this method is called, and the result will be
  # memoized to ensure subsequent calls do not return a different result.
  def include_datadog_rum_js?
    return false unless enabled? && complete_config?
    return @datadog_rum_config_requested if defined?(@datadog_rum_config_requested)
    return false unless @datadog_rum_config_opted_in
    @datadog_rum_config_requested = randomly_include?
  end

  def render_datadog_rum_js
    render partial: "shared/datadog_rum_js" if include_datadog_rum_js?
  end

  # indirection for testing purposes
  def random
    rand
  end

  private

  def enabled?
    Account.site_admin.feature_enabled?(:datadog_rum_js) && sample_rate > 0.0
  end

  def randomly_include?
    self.random <= sample_rate
  end

  def sample_rate
    datadog_rum_config[:sample_rate_percentage].to_f / 100
  end

  def datadog_rum_config
    @datadog_rum_config ||= Canvas::DynamicSettings.find("datadog-rum", tree: "config", service: "canvas")
  end

  def complete_config?
    %i[client_token application_id sample_rate_percentage].all? do |key|
      datadog_rum_config[key].present?
    end
  end
end

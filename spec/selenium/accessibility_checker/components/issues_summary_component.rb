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

require_relative "../../common"

class IssuesSummaryComponent
  include SeleniumDependencies

  def summary_container_selector
    "[data-testid='accessibility-issues-summary']"
  end

  def total_issues_selector
    "[data-testid='counter-number']"
  end

  def summary_container_exists?
    element_exists?(summary_container_selector)
  end

  def total_issues
    f(total_issues_selector)
  end

  def visible?
    summary_container_exists?
  end

  def total_count
    total_issues.text.to_i
  end
end

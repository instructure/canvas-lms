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

require_relative "../../../common"

class ProblemAreaComponent
  include SeleniumDependencies

  def problem_area_container_selector
    "[role='dialog'] h4"
  end

  def issue_description_selector
    "[role='dialog'] h3"
  end

  def problem_area_container
    f(problem_area_container_selector)
  end

  def problem_area_container_exists?
    element_exists?(problem_area_container_selector)
  end

  def visible?
    problem_area_container_exists?
  end

  def issue_description
    f(issue_description_selector).text
  end
end

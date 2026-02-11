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

require_relative "test_data_factory"

module AccessibilityChecker
  module BatchDataFactory
    include TestDataFactory

    def create_paginated_content(course, count: 25)
      count.times do |i|
        create_page_with(
          course,
          :missing_alt_text,
          title: "Paginated Page #{i + 1}"
        )
      end
    end
  end
end

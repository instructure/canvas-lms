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
module AccessibilityHelper
  MAX_RESOURCE_COUNT = 1000

  def exceeds_accessibility_scan_limit?
    # TODO: add caching with proper invalidation
    wiki_page_count = @context.wiki_pages.not_deleted.count
    assignment_count = @context.assignments.active.count
    attachment_count = @context.attachments.not_deleted.count

    total = wiki_page_count + assignment_count + attachment_count
    total > MAX_RESOURCE_COUNT
  end
end

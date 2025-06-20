# frozen_string_literal: true

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

module Accessibility
  module HasContext
    extend ActiveSupport::Concern

    included do
      belongs_to :wiki_page, optional: true
      belongs_to :assignment, optional: true
      belongs_to :attachment, optional: true

      validate :exactly_one_context_present
    end

    def context
      wiki_page || assignment || attachment
    end

    private

    def exactly_one_context_present
      contexts = [wiki_page_id, assignment_id, attachment_id].compact
      unless contexts.size == 1
        errors.add(:base, "Exactly one context must be present")
      end
    end
  end
end

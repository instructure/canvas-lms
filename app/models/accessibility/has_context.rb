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

      scope :for_context, lambda { |context|
        key = case context
              when WikiPage then :wiki_page_id
              when Assignment then :assignment_id
              when Attachment then :attachment_id
              else raise ArgumentError, "Unsupported context type: #{context.class.name}"
              end
        where(key => context.id)
      }

      validate :exactly_one_context_present
    end

    def context
      wiki_page || assignment || attachment
    end

    def context=(context_object)
      case context_object
      when WikiPage
        self.wiki_page = context_object
      when Assignment
        self.assignment = context_object
      when Attachment
        self.attachment = context_object
      else
        raise ArgumentError, "Unsupported context type: #{context_object.class.name}"
      end
    end

    def context_id_and_type
      if wiki_page_id
        [wiki_page_id, "WikiPage"]
      elsif assignment_id
        [assignment_id, "Assignment"]
      elsif attachment_id
        [attachment_id, "Attachment"]
      else
        [nil, nil]
      end
    end

    def context_url
      id, type = context_id_and_type
      return nil unless id && type

      case type
      when "WikiPage"
        Rails.application.routes.url_helpers.course_wiki_page_url(course_id, id, only_path: true)
      when "Assignment"
        Rails.application.routes.url_helpers.course_assignment_url(course_id, id, only_path: true)
      when "Attachment"
        Rails.application.routes.url_helpers.course_files_url(course_id, preview: id, only_path: true)
      else
        nil
      end
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

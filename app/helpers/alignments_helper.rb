# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module AlignmentsHelper
  def link_to_outcome_alignment(context, outcome, alignment = nil)
    html_class = [
      "title"
    ]
    html_class << "icon-#{alignment.content_type.downcase}" if alignment
    link_to(alignment.try(:title) || nbsp, outcome_alignment_url(context, outcome, alignment), {
              class: html_class
            })
  end

  def outcome_alignment_tag(context, outcome, alignment = nil, &)
    options = {
      id: "alignment_#{alignment.try(:id) || "blank"}",
      class: [
        "alignment",
        alignment.try(:content_type_class),
        alignment.try(:graded?) ? "also_assignment" : nil
      ].compact,
      data: {
        id: alignment.try(:id),
        has_rubric_association: alignment.try(:has_rubric_association?),
        url: outcome_alignment_url(
          context, outcome, alignment
        )
      }.compact_blank!
    }
    options[:style] = hidden unless alignment

    content_tag(:li, options, &)
  end

  def outcome_alignment_url(context, outcome, alignment = nil)
    if alignment.present?
      [
        context_prefix(alignment.context_code),
        "outcomes",
        outcome.id,
        "alignments",
        alignment.id
      ].join("/")
    elsif !context.is_a?(Account)
      context_url(
        context,
        :context_outcome_alignment_redirect_url,
        outcome.id,
        "{{ id }}"
      )
    else
      nil
    end
  end
end

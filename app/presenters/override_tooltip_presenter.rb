# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class OverrideTooltipPresenter < OverrideListPresenter
  DEFAULT_MAX_DATES = 10

  def initialize(assignment = nil, user = nil, opts = {})
    super(assignment, user)
    @opts = opts
  end

  def default_link_text
    I18n.t("#assignments.multiple_due_dates", "Multiple Due Dates")
  end

  def link_text
    @opts[:text] || default_link_text
  end

  def link_href
    @opts[:href]
  end

  def more_message
    return "" unless dates_hidden > 0

    I18n.t("#tooltips.vdd.more_message", "and %{count} more...", count: dates_hidden)
  end

  # Pass in a :max_dates option to adjust how many dates are shown
  # before "and # more..." is shown at the bottom
  def max_dates
    @opts[:max_dates] || self.class::DEFAULT_MAX_DATES
  end

  def total_dates
    visible_due_dates.length
  end

  def dates_visible
    [total_dates, max_dates].min
  end

  def dates_hidden
    total_dates - dates_visible
  end

  def selector
    "#{assignment.class.to_s.demodulize.downcase}_#{assignment.id}"
  end

  def due_date_summary
    visible_due_dates[0...dates_visible].map do |date|
      { due_for: date[:due_for], due_at: date[:due_at] }
    end
  end

  def as_json
    {
      selector:,
      link_text:,
      link_href:,
      due_dates: due_date_summary,
      more_message:
    }
  end
end

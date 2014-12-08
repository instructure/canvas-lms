#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

module AssignmentsHelper
  def completed_link_options
    {
      class: 'pass',
      title: I18n.t('tooltips.finished', 'finished')
    }
  end

  def in_progress_link_options
    {
      class: 'warning',
      title: I18n.t('tooltips.incomplete', 'incomplete')
    }
  end

  def multiple_due_dates(assignment)
    # can use this method as the single source of rendering multiple due dates
    # for now, just text, but eventually, a bubble/dialog/link/etc, rendering
    # the information contained in the varied_due_date parameter
    I18n.t '#assignments.multiple_due_dates', 'Multiple Due Dates'
  end

  def student_peer_review_link_for(context, assignment, assessment)
    link_options = assessment.completed? ? completed_link_options : in_progress_link_options
    link_to assessment.asset_user_name, context_url(context, :context_assignment_submission_url, assignment.id, assessment.asset.user_id), link_options
  end

  def due_at(assignment, user, format='datetime')
    if assignment.multiple_due_dates_apply_to?(user)
      multiple_due_dates(assignment)
    else
      assignment = assignment.overridden_for(user)
      send("#{format}_string", assignment.due_at, :short)
    end
  end
end

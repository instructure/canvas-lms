#
# Copyright (C) 2011 Instructure, Inc.
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

module CoursesHelper
  def icon_data(opts = {})
    context      = opts[:context]
    contexts     = opts[:contexts]
    current_user = opts[:current_user]
    recent_event = opts[:recent_event]
    submission   = opts[:submission]
    student_only = opts[:student_only]

    return [nil, "calendar"] unless recent_event.is_a?(Assignment)

    # because this happens in a sidebar, the context may be wrong. check and fix
    # it if that's the case.
    context = context.class == recent_event.class && context.id == recent_event.context_id ?
      context : recent_event.context

    icon_data = [nil, 'icon-grading-gray']
    if can_do(context, current_user, :participate_as_student)
      icon_data = submission && submission.workflow_state != 'unsubmitted' ? [submission.readable_state, 'icon-grading'] : [t('#courses.recent_event.not_submitted', 'not submitted'), "icon-grading-gray"]
      icon_data[0] = nil if !recent_event.expects_submission?
    elsif !student_only && can_do(context, current_user, :manage_grades)
      # no submissions
      if !recent_event.has_submitted_submissions?
        icon_data = [t('#courses.recent_event.no_submissions', 'no submissions'), "icon-grading-gray"]
      # all received submissions graded (but not all turned in)
      elsif recent_event.submitted_count < context.students.size && !current_user.assignments_needing_grading(:contexts => contexts).include?(recent_event)
        icon_data = [t('#courses.recent_event.no_new_submissions', 'no new submissions'), "icon-grading-gray"]
      # all submissions turned in and graded
      elsif !current_user.assignments_needing_grading(:contexts => contexts).include?(recent_event)
        icon_data = [t('#courses.recent_event.all_graded', 'all graded'), 'icon-grading']
      # assignments need grading
      else
        icon_data = [t('#courses.recent_event.needs_grading', 'needs grading'), "icon-grading-gray"]
      end
    end

    icon_data
  end

  def recent_event_url(recent_event)
    context = recent_event.context
    if recent_event.is_a?(Assignment)
      url = context_url(context, :context_assignment_url, :id => recent_event.id)
    else
      url = calendar_url_for(nil, {
        :query => {:month => recent_event.start_at.month, :year => recent_event.start_at.year},
        :anchor => "calendar_event_" + recent_event.id.to_s
      })
    end

    url
  end

  # Public: Display the given user count, or "None" if it's 0.
  #
  # count - The count to display (e.g. 7)
  #
  # Returns a text string.
  def user_count(count)
    count == 0 ? t('#courses.settings.none', 'None') : count
  end

  def readable_grade(submission)
    if submission.grade and
       submission.workflow_state == 'graded'
      if submission.grading_type == 'points' and
         submission.assignment and
         submission.assignment.respond_to?(:points_possible)
         score_out_of_points_possible(submission.grade, submission.assignment.points_possible)
      else
        submission.grade.to_s.capitalize
      end
    else
      nil
    end
  end

  def skip_custom_role?(cr)
    cr[:count] == 0 && cr[:workflow_state] == 'inactive'
  end


end

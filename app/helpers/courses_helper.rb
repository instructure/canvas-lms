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

module CoursesHelper
  def icon_data(opts = {})
    context      = opts[:context]
    contexts     = opts[:contexts]
    current_user = opts[:current_user]
    recent_event = opts[:recent_event]
    submission   = opts[:submission]
    student_only = opts[:student_only]
    show_assignment_type_icon = opts[:show_assignment_type_icon]

    return [nil, "Quiz", 'icon-quiz'] if recent_event.is_a?(Quizzes::Quiz)
    return [nil, "Event", "icon-calendar-day"] unless recent_event.is_a?(Assignment)

    event_type = ['Assignment', 'icon-assignment']
    event_type = ['Quiz', 'icon-quiz'] if recent_event.submission_types == 'online_quiz'
    event_type = ['Discussion', 'icon-discussion'] if recent_event.submission_types == 'discussion_topic'

    # because this happens in a sidebar, the context may be wrong. check and fix
    # it if that's the case.
    context = context.class == recent_event.class && context.id == recent_event.context_id ?
      context : recent_event.context

    icon_data = [nil] + event_type

    if can_do(context, current_user, :participate_as_student)
      if submission && submission.workflow_state != 'unsubmitted'
        event_type = ['', 'icon-check'] unless show_assignment_type_icon
        icon_data = [submission.readable_state] + event_type
      else
        icon_data = [t('#courses.recent_event.not_submitted', 'not submitted')] + event_type
      end
      icon_data[0] = nil if !recent_event.expects_submission?
    elsif !student_only && can_do(context, current_user, :manage_grades)
      # no submissions
      if !recent_event.has_submitted_submissions?
        icon_data = [t('#courses.recent_event.no_submissions', 'no submissions')] + event_type
      # all received submissions graded (but not all turned in)
      elsif recent_event.submitted_count < context.students.size &&
        !current_user.assignments_needing_grading(:contexts => contexts).include?(recent_event)
        icon_data = [t('#courses.recent_event.no_new_submissions', 'no new submissions')] + event_type
      # all submissions turned in and graded
      elsif !current_user.assignments_needing_grading(:contexts => contexts).include?(recent_event)
        icon_data = [t('#courses.recent_event.all_graded', 'all graded')] + event_type
      # assignments need grading
      else
        icon_data = [t('#courses.recent_event.needs_grading', 'needs grading')] + event_type
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
        i18n_grade(submission.grade, submission.grading_type).to_s.capitalize
      end
    end
  end

  def skip_custom_role?(cr)
    cr[:count] == 0 && cr[:workflow_state] == 'inactive'
  end

  def user_type(course, user)
    enrollment = course.enrollments.find_by(user: user)

    if enrollment.nil?
      return course.account_membership_allows(user) ? "admin" : nil
    end

    type = enrollment.type.remove(/Enrollment/).downcase
    type = "student" if %w/studentview observer/.include?(type)

    type
  end

  def why_cant_i_enable_master_course(course)
    return nil if MasterCourses::MasterTemplate.is_master_course?(course)

    if MasterCourses::ChildSubscription.is_child_course?(course)
      t('Course is already associated with a blueprint')
    elsif course.student_enrollments.not_fake.exists?
      t("Cannot have a blueprint course with students")
    else
      nil
    end
  end
end

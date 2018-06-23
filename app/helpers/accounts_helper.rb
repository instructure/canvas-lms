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

module AccountsHelper
  def show_last_batch
    @last_batch && !(@current_batch && @current_batch.importing?)
  end

  def print_messages(batch)
    return '' unless batch
    render :partial => 'accounts/sis_batch_messages', :object => batch
  end

  def print_counts(batch)
    return '' unless batch.data && batch.data[:counts]
    render :partial => 'accounts/sis_batch_counts', :object => batch
  end

  def show_code_and_term_for(course)
    show_term = course.enrollment_term && !course.enrollment_term.default_term?
    show_code = course.course_code != course.name
    "#{course.course_code if show_code}#{', ' if show_term && show_code}#{course.enrollment_term.name if show_term}"
  end

  def turnitin_originality_options
    [
      [I18n.t('#turnitin_settings.originality_report_visible_immediately', "Immediately"), 'immediate'],
      [I18n.t('#turnitin_settings.originality_report_visible_after_grading', "After the assignment is graded"), 'after_grading'],
      [I18n.t('#turnitin_settings.originality_report_visible_after_due_date', "After the Due Date"), 'after_due_date'],
      [I18n.t('#turnitin_settings.originality_report_never', "Never"), 'never']
    ]
  end

  def dashboard_view_options(account)
    [
      [I18n.t('Card View'), 'cards'],
      [I18n.t('Recent Activity'), 'activity'],
    ].tap { |opts| opts << [I18n.t('List View'), 'planner'] if account.root_account.feature_enabled?(:student_planner)}
  end
end

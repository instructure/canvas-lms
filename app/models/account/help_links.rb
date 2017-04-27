#
# Copyright (C) 2016 - present Instructure, Inc.
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

class Account::HelpLinks
  def self.default_links
    [
      {
        :available_to => ['student'],
        :text => I18n.t('#help_dialog.instructor_question', 'Ask Your Instructor a Question'),
        :subtext => I18n.t('#help_dialog.instructor_question_sub', 'Questions are submitted to your instructor'),
        :url => '#teacher_feedback',
        :type => 'default'
      },
      {
        :available_to => ['user', 'student', 'teacher', 'admin'],
        :text => I18n.t('#help_dialog.search_the_canvas_guides', 'Search the Canvas Guides'),
        :subtext => I18n.t('#help_dialog.canvas_help_sub', 'Find answers to common questions'),
        :url => Setting.get('help_dialog_canvas_guide_url', 'http://community.canvaslms.com/community/answers/guides'),
        :type => 'default'
      },
      {
        :available_to => ['user', 'student', 'teacher', 'admin'],
        :text => I18n.t('#help_dialog.report_problem', 'Report a Problem'),
        :subtext => I18n.t('#help_dialog.report_problem_sub', 'If Canvas misbehaves, tell us about it'),
        :url => '#create_ticket',
        :type => 'default'
      }
    ]
  end
end

#
# Copyright (C) 2014 - present Instructure, Inc.
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

Feature.register('quiz_log_auditing' => {
  display_name: -> {
    I18n.t('features.quiz_log_auditing', 'Quiz Log Auditing')
  },
  description: -> {
    I18n.t 'quiz_log_auditing_desc', <<-TEXT
      Enable the tracking of events for a quiz submission, and the ability
      to view a log of those events once a submission is made.
    TEXT
  },
  applies_to: 'Course',
  state: 'allowed',
  beta: true
})

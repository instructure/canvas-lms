#
# Copyright (C) 2018 - present Instructure, Inc.
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

Feature.register(
  anonymous_moderated_marking: {
    display_name: -> { I18n.t('Anonymous Moderated Marking') },
    description:  -> {
      I18n.t <<~DESCRIPTION
        Anonymous Moderated Marking allows teachers to select moderators to anonymously grade assignments. After which a moderator can select or supply a custom grade.
      DESCRIPTION
    },
    applies_to: 'Account',
    state: 'hidden',
    root_opt_in: true,
    beta: true,
    development: true
  },
  anonymous_marking:  {
    display_name: -> { I18n.t 'Anonymous Grading' },
    description: -> {
      I18n.t <<~DESCRIPTION
        Enable anonymous grading of assignments.
      DESCRIPTION
    },
    applies_to: 'Course',
    state: 'allowed',
    root_opt_in: true,
    beta: true
  },
  anonymous_moderated_marking_audit_trail: {
    display_name: -> { I18n.t('Anonymous Moderated Marking Audit Trail') },
    description: -> {
      I18n.t <<~DESCRIPTION
        Allows assessors to view the assessment audit tray in SpeedGrader for anonymous or moderated assignments.
      DESCRIPTION
    },
    applies_to: 'Account',
    state: 'allowed',
    root_opt_in: true,
    beta: true
  }
)

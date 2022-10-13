/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = useI18nScope('permissions_templates_3')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to create collaborations.'),
    },
    {
      description: I18n.t('Allows user to view, edit, and delete collaborations they created.'),
    },
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        'To allow view edit delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If Course Content - add / edit / delete is enabled and Student Collaborations - create is disabled, the user will not be able to create new collaborations but will be able to view edit delete all collaborations.'
      ),
    },
    {
      description: I18n.t(
        'To add students to a collaboration, Users - view list must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To add a course group to a collaboration, Groups - add must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to create collaborations.'),
    },
    {
      description: I18n.t('Allows user to view, edit, and delete conferences they created.'),
    },
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        'To allow view, edit, and delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If Course Content - add / edit / delete is enabled and Student Collaborations - create is disabled, the user will not be able to create new collaborations but will be able to view, edit, and delete all collaborations.'
      ),
    },
    {
      description: I18n.t(
        'To add students to a collaboration, Users - view list must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To add a course group to a collaboration, Groups - add must also be enabled.'
      ),
    },
  ]
)

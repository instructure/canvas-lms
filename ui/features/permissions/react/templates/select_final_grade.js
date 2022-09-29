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

const I18n = useI18nScope('permissions_templates_62')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to select final grade for moderated assignments.'),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To add students to a moderation set, Grades - view all grades must also be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To publish final grades for a moderated assignment, Grades - edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To post or hide grades for a moderated assignment, Grades - edit must also be enabled.'
      ),
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(
        'To review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to select final grade for moderated assignments.'),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To add students to a moderation set, Grades - view all grades must also be enabled.'
      ),
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(
        'To review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To publish final grades for a moderated assignment, Grades - edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To post or hide grades for a moderated assignment, Grades - edit must also be enabled.'
      ),
    },
  ]
)

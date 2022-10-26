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

const I18n = useI18nScope('permissions_templates_4')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to create new conferences in courses and groups.'),
    },
    {
      description: I18n.t('Allows user to start conferences they created.'),
    },
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(
        'To allow full management of conferences created by the user or others, the Course Content permission must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To end a long-running conference, the Course Content permission must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If the Course Content permission enabled and Web Conferences - create is disabled, the user can still manage conferences.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to create new conferences in courses and groups.'),
    },
    {
      description: I18n.t('Allows user to start conferences they created.'),
    },
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(
        'To allow full management of conferences created by the user or others, the Course Content permission must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To end a long-running conference, the Course Content permission must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If the Course Content permission enabled and Web Conferences - create is disabled, the user can still manage conferences.'
      ),
    },
  ]
)

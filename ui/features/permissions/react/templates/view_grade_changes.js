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

const I18n = useI18nScope('permissions_templates_71')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'Determines visibility of the Grade Change Activity option in the Admin Tools Logging tab.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('To search by grader or student ID, Users - view must also be enabled.'),
    },
    {
      description: I18n.t(
        'To search by course ID or assignment ID, Grades - edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To search by assignment ID only, Grades - view all grades must also be enabled.'
      ),
    },
  ],
  [],
  []
)

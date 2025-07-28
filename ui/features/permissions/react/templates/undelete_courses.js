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

import {useScope as createI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = createI18nScope('permissions_templates_65')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t('Allows user to access the Restore Courses tab in Admin Tools.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t(
        'To search for a course in the Restore Courses tab, Course Content - view must also be enabled.',
      ),
    },
    {
      description: I18n.t(
        'To restore a deleted course in an account, Manage Courses - delete and Course Content - view must also be enabled.',
      ),
    },
  ],
  [],
  [],
)

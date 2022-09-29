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

const I18n = useI18nScope('permissions_templates_72')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t('Allows user to view the group home pages of all student groups.'),
    },
    {
      description: I18n.t(
        'Allows students to access other student groups within a group set with a direct link.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'By default students are able to create groups; to restrict students from creating groups, do not select the Let students organize their own groups checkbox in Course Settings.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t('Allows user to view the group home pages of all student groups.'),
    },
    {
      description: I18n.t(
        'Allows students to access other student groups within a group set with a direct link.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'By default students are able to create groups; to restrict students from creating groups, do not select the Let students organize their own groups checkbox in Course Settings.'
      ),
    },
  ]
)

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

const I18n = useI18nScope('permissions_templates_59')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t('Allows user to view and configure reports in Account Settings.'),
    },
    {
      description: I18n.t('Allows user to view Access Reports.'),
    },
    {
      description: I18n.t(
        'Allows user to view last activity and total activity information on the People page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To view Last Activity and Total Activity information on the Course People page, Users - view list must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To access a Course People page, Users - view list must also be enabled.'
      ),
    },
    {
      title: I18n.t('Reports (Course)'),
      description: I18n.t(
        'To access the Student Interactions report, Grades - view all grades must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view the Course Statistics button in Course Settings.'),
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to view Last Activity and Total Activity information on the People page.'
      ),
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t('Allows user to view Last Activity and Total Activity reports.'),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To access the People Page, Users - view list must be enabled.'),
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Grades - view all grades must also be enabled.'
      ),
    },
  ]
)

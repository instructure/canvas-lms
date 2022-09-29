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

const I18n = useI18nScope('permissions_templates_67')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Analytics (Account)'),
      description: I18n.t('Allows user to view account analytics.'),
    },
    {
      title: I18n.t('Analytics (Course)'),
      description: I18n.t('Allows user to view course analytics through the course dashboard.'),
    },
    {
      description: I18n.t('Allows user to view student analytics.'),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Grades - view all grades must also be enabled.'
      ),
    },
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'The analytics feature must be enabled in Account Settings to view analytics pages.'
      ),
    },
    {
      description: I18n.t(
        'To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To view student analytics, Users - view list and Grades - view all grades​ must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'Allows user to view course and student analytics from the Course Home Page or People page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Grades - view all grades must also be enabled'
      ),
    },
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'The analytics feature must be enabled in Account Settings to view analytics pages.'
      ),
    },
    {
      description: I18n.t(
        'To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account.'
      ),
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view student analytics, Users - view list and Grades - view all grades​ must also be enabled.'
      ),
    },
  ]
)

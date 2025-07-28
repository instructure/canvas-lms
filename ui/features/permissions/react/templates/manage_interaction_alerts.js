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

const I18n = createI18nScope('permissions_templates_35')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to configure alerts in Course Settings.'),
    },
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'This is an account setting that must be enabled by a Customer Success Manager. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student-teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.',
      ),
    },
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to configure alerts in Course Settings.'),
    },
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'Alerts must be configured for the institution. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student-teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.',
      ),
    },
  ],
)

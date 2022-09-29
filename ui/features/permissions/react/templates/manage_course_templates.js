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

const I18n = useI18nScope('permissions_templates_25')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Templates - create'),
      description: I18n.t('Allows user to set a template for an account.'),
    },
    {
      description: I18n.t(
        'Allows user to select a course as a course template in Course Settings.'
      ),
    },
    {
      description: I18n.t('Allows user to view names of course templates in the root account.'),
    },
    {
      title: I18n.t('Course Templates - delete'),
      description: I18n.t(
        'Allows user to remove a course as a course template in Course Settings.'
      ),
    },
    {
      description: I18n.t('Allows user to set an account to not use a template.'),
    },
    {
      title: I18n.t('Course Templates - edit'),
      description: I18n.t('Allows user to change the template being used by an account.'),
    },
    {
      description: I18n.t('Allows user to view names of course templates in the root account.'),
    },
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'To access the Account Settings tab, Account-level settings - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(
        'To create a new course to use as a course template, Courses - add must also be enabled.'
      ),
    },
  ],
  [],
  []
)

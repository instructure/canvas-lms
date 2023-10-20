/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

const I18n = useI18nScope('permissions_templates_78')

export const template = generateActionTemplates([
  {
    title: I18n.t('Manage Temporary Enrollments'),
    description: I18n.t(
      'Temporarily enroll a user into a course. This temporary enrollment is paired up with another enrollment within the course.'
    ),
  },
  {
    description: I18n.t(
      'The temporarily enrolled user can only view and participate in a course between the start and end dates that were chosen when making the temporary enrollment.'
    ),
  },
  {
    title: I18n.t('Temporary Enrollments - add'),
    description: I18n.t(
      'Allows users to add a temporary enrollment with a start date, end date, and role'
    ),
  },
  {
    title: I18n.t('Temporary Enrollments - edit'),
    description: I18n.t('Allows users to edit an existing temporary enrollment'),
  },
  {
    title: I18n.t('Temporary Enrollments - delete'),
    description: I18n.t('Allows users to delete a temporary enrollment'),
  },
])

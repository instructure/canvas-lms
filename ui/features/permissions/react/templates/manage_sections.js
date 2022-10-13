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

const I18n = useI18nScope('permissions_templates_42')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Sections - add'),
      description: I18n.t('Allows user to add course sections in Course Settings.'),
    },
    {
      title: I18n.t('Course Sections - edit'),
      description: I18n.t('Allows user to rename course sections.'),
    },
    {
      description: I18n.t('Allows user to change start and end dates for course sections.'),
    },
    {
      description: I18n.t('Allows user to cross-list sections.'),
    },
    {
      title: I18n.t('Course Sections - delete'),
      description: I18n.t('Allows user to delete course sections.'),
    },
    {
      description: I18n.t('Allows user to delete a user from a course section.'),
    },
  ],
  [
    {
      title: I18n.t('Cross-Listing'),
      description: I18n.t(
        'To cross-list sections, Course Sections - edit and Courses - manage must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Course Sections - add'),
      description: I18n.t('Allows user to add course sections in Course Settings.'),
    },
    {
      title: I18n.t('Course Sections - edit'),
      description: I18n.t(
        'Allows user to rename course sections. Allows user to change start and end dates for course sections. Allows user to cross-list sections.'
      ),
    },
    {
      title: I18n.t('Course Sections - delete'),
      description: I18n.t('Allows user to delete course sections.'),
    },
    {
      description: I18n.t('Allows user to delete a user from a course section.'),
    },
  ],
  [
    {
      title: I18n.t('Cross-Listing'),
      description: I18n.t(
        'To cross-list sections, Course Sections - edit must be enabled. The user must also be enrolled as an instructor in the courses being cross-listed.'
      ),
    },
  ]
)

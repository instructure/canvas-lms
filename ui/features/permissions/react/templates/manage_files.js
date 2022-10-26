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

const I18n = useI18nScope('permissions_templates_32')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Files - add'),
      description: I18n.t('Allows user to add course files and folders.'),
    },
    {
      description: I18n.t('Allows user to import a zip file.'),
    },
    {
      title: I18n.t('Course Files - edit'),
      description: I18n.t('Allows user to edit course files and folders.'),
    },
    {
      title: I18n.t('Course Files - delete'),
      description: I18n.t('Allows user to delete course files and folders.'),
    },
  ],
  [
    {
      title: I18n.t('Course Files'),
      description: I18n.t(
        'If one or all permissions are disabled, user can still view and download files into a zip file.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import files using the Course Import Tool, Course files - add and Course Content - add / edit / delete must be enabled.'
      ),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings for course files, Course files - edit, Blueprint Courses - add / edit / associate / delete, and Courses - manage must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Course Files - add'),
      description: I18n.t('Allows user to add course files and folders.'),
    },
    {
      description: I18n.t('Allows user to import a zip file.'),
    },
    {
      title: I18n.t('Course Files - edit'),
      description: I18n.t('Allows user to edit course files and folders.'),
    },
    {
      title: I18n.t('Course Files - delete'),
      description: I18n.t('Allows user to delete course files and folders.'),
    },
  ],
  [
    {
      title: I18n.t('Course Files'),
      description: I18n.t(
        'If one or all permissions are disabled, user can still view and download files into a zip file.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import files using the Course Import Tool, Course files - add and Course Content - add / edit / delete must be enabled.'
      ),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.'),
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      ),
    },
  ]
)

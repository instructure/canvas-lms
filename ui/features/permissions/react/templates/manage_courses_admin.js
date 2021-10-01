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

import I18n from 'i18n!permissions_templates_29'
import {generateActionTemplates} from '../generateActionTemplates'

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Allows user to sync Blueprint Courses.')
    },
    {
      description: I18n.t('Allows user to view Blueprint Sync history.')
    },
    {
      title: I18n.t('Courses (Account Navigation)'),
      description: I18n.t('Allows user to view and manage courses in the account.')
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t('Allows user to view the Course Setup Checklist button.')
    },
    {
      title: I18n.t('Course Settings (Course Details)'),
      description: I18n.t('Allows user to access the Navigation tab.')
    },
    {
      description: I18n.t(
        'Allows user to edit course image, name, course code, time zone, subaccount, term, and other options in Course Details tab.'
      )
    },
    {
      description: I18n.t(
        'Allows user to access Student View (test student), Copy this Course, and Permanently Delete Course buttons.'
      )
    },
    {
      title: I18n.t('Student Context Cards'),
      description: I18n.t(
        'Allows user to view student context cards in announcement and discussion replies.'
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'If this permission is enabled, but Blueprint Courses - add / edit / associate / delete is not enabled, users can still sync Blueprint Courses and view Sync history.'
      )
    },
    {
      title: I18n.t('Course Content'),
      description: I18n.t(
        'To manage course content, Course Content - add / edit / delete must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view Choose Home Page and Course Setup Checklist buttons, Course Content - view must also be enabled. (Teachers, designers, and TAs can set the home page of a course, regardless of their permissions.)'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To cross-list a section, Manage Course Sections - edit must also be enabled.'
      )
    },
    {
      description: I18n.t('To edit the course SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      title: I18n.t('Courses (Account Navigation)'),
      description: I18n.t(
        'To access the Courses link in Account Navigation, Courses - view list must also be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To view grades in a course, Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('Student Context Cards'),
      description: I18n.t(
        'Student context cards must be enabled for an account by an admin. If this permission is not enabled, users can still view context cards through the Gradebook.'
      )
    }
  ]
)

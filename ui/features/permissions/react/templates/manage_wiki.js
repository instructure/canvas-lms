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

const I18n = useI18nScope('permissions_templates_49')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Pages - create'),
      description: I18n.t('Allows user to create course pages.'),
    },
    {
      title: I18n.t('Pages - delete'),
      description: I18n.t('Allows user to delete course pages.'),
    },
    {
      title: I18n.t('Pages - update'),
      description: I18n.t('Allows user to edit course pages.'),
    },
    {
      description: I18n.t('Allows user to define users allowed to edit the page.'),
    },
    {
      description: I18n.t('Allows user to add page to student to-do list.'),
    },
    {
      description: I18n.t('Allows user to publish and unpublish pages.'),
    },
    {
      description: I18n.t('Allows user to view page history and set front page.'),
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint Course lock settings in the Pages index page and for an individual page in a Blueprint master course.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.'),
    },
    {
      description: I18n.t(
        'To edit lock settings on the Pages index page, Pages - update, Blueprint Courses - add / edit / associate / delete, and Courses - manage.'
      ),
    },
    {
      description: I18n.t(
        'However, if these additional permissions are enabled, but the Pages - update permission is not enabled, the user can still adjust content lock settings on individual pages in a Blueprint Master Course.'
      ),
    },
    {
      title: I18n.t('Student Page History'),
      description: I18n.t(
        'Students can edit and view page history if allowed in the options for an individual page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Pages - create'),
      description: I18n.t('Allows user to create course pages.'),
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint lock settings for individual pages in a Blueprint Master Course.'
      ),
    },
    {
      title: I18n.t('Pages - delete'),
      description: I18n.t('Allows user to delete course pages.'),
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint lock settings for individual pages in a Blueprint Master Course.'
      ),
    },
    {
      title: I18n.t('Pages - update'),
      description: I18n.t('Allows user to edit course pages.'),
    },
    {
      description: I18n.t('Allows user to define users allowed to edit the page.'),
    },
    {
      description: I18n.t('Allows user to add page to student to-do list.'),
    },
    {
      description: I18n.t('Allows user to publish and unpublish pages.'),
    },
    {
      description: I18n.t('Allows user to view page history and set front page.'),
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint lock settings in the Pages index page and for an individual page in a Blueprint master course.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.'),
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      ),
    },
    {
      description: I18n.t(
        'If the Pages - Update permission is disabled, the user can still adjust content lock settings on individual pages in a Blueprint Master Course.'
      ),
    },
    {
      title: I18n.t('Student Page History'),
      description: I18n.t(
        'Students can edit and view page history if allowed in the options for an individual page.'
      ),
    },
  ]
)

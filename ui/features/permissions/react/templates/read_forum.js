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

const I18n = useI18nScope('permissions_templates_57')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint content lock settings on individual discussions.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to view the Discussions link in Course Navigation.'),
    },
    {
      description: I18n.t('Allows user to view course discussions.'),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings from the Discussions index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a discussion to Commons, Courses - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('To manage discussions, Discussions - moderate must also be enabled.'),
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must also be enabled.'),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint content lock settings on individual settings if the user is enrolled in a Blueprint master course.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to view the Discussions link in Course Navigation.'),
    },
    {
      description: I18n.t('Allows user to view course discussions.'),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint Courses must be enabled for an account by an admin.'),
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course with a teacher, TA, or designer role.'
      ),
    },
    {
      description: I18n.t(
        'To edit Blueprint lock settings from the Discussions index page, Discussions - moderate must also be enabled.'
      ),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a discussion to Commons, Course Content - add / edit / delete must also be enabled.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('To manage discussions, Discussions - moderate must also be enabled.'),
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must also be enabled.'),
    },
  ]
)

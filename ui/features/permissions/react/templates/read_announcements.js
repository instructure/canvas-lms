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

const I18n = useI18nScope('permissions_templates_53')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view the Announcements link in Course Navigation.'),
    },
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view course announcements.'),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        'To view recent announcements on the home page, Course content - view must be enabled, and the Show recent announcements on Course home page checkbox must be selected in Course Settings.'
      ),
    },
    {
      description: I18n.t(
        'To manage course announcements, Discussions - moderate ​must also be enabled.'
      ),
    },
    {
      title: I18n.t('Global Announcements'),
      description: I18n.t(
        'This permission only affects course announcements; to manage global announcements, Global Announcements - add / edit / delete​ must be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to access the Announcements link in Course Navigation.'),
    },
    {
      description: I18n.t('Allows user to view course announcements.'),
    },
    {
      description: I18n.t('Allows user to view recent announcements on the Course Home Page.'),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To add announcements, Discussions - moderate must also be enabled.'),
    },
    {
      description: I18n.t(
        'To view recent announcements on the home page, the Show recent announcements on Course home page checkbox must be selected in Course Settings.'
      ),
    },
  ]
)

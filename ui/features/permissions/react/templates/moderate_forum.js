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

const I18n = useI18nScope('permissions_templates_50')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view the New Announcement button in the Home page.'),
    },
    {
      description: I18n.t('Allows user to add announcements in the Announcements page.'),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Discussions index page in a Blueprint master course.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to add discussions in the Discussions page.'),
    },
    {
      description: I18n.t(
        'Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics in the Discussions page.'
      ),
    },
    {
      description: I18n.t('Allows user to edit discussion topics.'),
    },
    {
      description: I18n.t('Allows user to view all replies within a discussion topic.'),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To view announcements, Announcements - view must also be enabled.'),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings on the Discussions index page, Courses - manage and Discussions - view must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If the additional permissions are enabled, but this permission is not enabled, lock settings can be edited on individual discussions.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.'
      ),
    },
    {
      description: I18n.t('To view discussions in a course, Discussions - view must be enabled.'),
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must be enabled.'),
    },
    {
      description: I18n.t('To edit a discussion, Discussions - moderate must also be enabled.'),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view the New Announcement button in the Home page.'),
    },
    {
      description: I18n.t('Allows user to add announcements in the Announcements page.'),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Discussions index page in a Blueprint master course.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to add discussions in the Discussions page.'),
    },
    {
      description: I18n.t(
        'Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics in the Discussions page.'
      ),
    },
    {
      description: I18n.t('Allows user to edit discussion topics.'),
    },
    {
      description: I18n.t('Allows user to view all replies within a discussion topic.'),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To view announcements, Announcements - view must also be enabled.'),
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
    {
      description: I18n.t(
        'If this setting is disabled, and Discussions - view is enabled, the user can still adjust content lock settings on individual discussions in a Blueprint master course.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.'
      ),
    },
    {
      description: I18n.t('To view discussions in a course, Discussions - view must be enabled.'),
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must be enabled.'),
    },
    {
      description: I18n.t('To edit a discussion, Discussions - moderate must also be enabled.'),
    },
  ]
)

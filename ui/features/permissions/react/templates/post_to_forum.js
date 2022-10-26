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

const I18n = useI18nScope('permissions_templates_52')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to reply to a discussion post.'),
    },
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'To view discussions in a course, Discussions - view must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If the option requiring users to post before seeing replies is selected in a discussion, users must post a reply to view all posts unless Discussions - moderate is also enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to reply to a discussion post.'),
    },
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'To view discussions in a course, Discussions - view must also be enabled.'
      ),
    },
    {
      description: I18n.t('To manage discussions, Discussions - moderate must also be enabled.'),
    },
  ]
)

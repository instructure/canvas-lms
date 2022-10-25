/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const I18n = useI18nScope('permissions_templates_77')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Submissions'),
      description: I18n.t('Allows instructors to submit file attachments on behalf of a student.'),
    },
  ],
  [
    {
      title: I18n.t('Submissions'),
      description: I18n.t('Once enabled, this option is visible in gradebook for instructors.'),
    },
    {
      description: I18n.t(
        "Instructors are not bound by attempt limits, but an instructor's submission WILL count as a student's attempt."
      ),
    },
  ],
  [
    {
      title: I18n.t('Submissions'),
      description: I18n.t('Allows instructors to submit file attachments on behalf of a student.'),
    },
  ],
  [
    {
      title: I18n.t('Submissions'),
      description: I18n.t('Once enabled, this option is visible in gradebook for instructors.'),
    },
    {
      description: I18n.t(
        "Instructors are not bound by attempt limits, but an instructor's submission WILL count as a student's attempt."
      ),
    },
  ]
)

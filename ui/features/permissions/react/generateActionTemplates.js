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

import {useScope as createI18nScope} from '@canvas/i18n'
import {COURSE, ACCOUNT} from '@canvas/permissions/react/propTypes'

const I18n = createI18nScope('permissions_detail_sections')

export const PERMISSION_DETAIL_SECTIONS = [
  {title: () => I18n.t('What it does'), key: 'what_it_does'},
  {title: () => I18n.t('Additional considerations'), key: 'additional_considerations'},
]

export const generateActionTemplates = (
  accountDetails,
  accountConsiderations,
  courseDetails,
  courseConsiderations,
) => ({
  [ACCOUNT]: {
    [PERMISSION_DETAIL_SECTIONS[0].key]: accountDetails,
    [PERMISSION_DETAIL_SECTIONS[1].key]: accountConsiderations,
  },
  [COURSE]: {
    [PERMISSION_DETAIL_SECTIONS[0].key]: courseDetails,
    [PERMISSION_DETAIL_SECTIONS[1].key]: courseConsiderations,
  },
})

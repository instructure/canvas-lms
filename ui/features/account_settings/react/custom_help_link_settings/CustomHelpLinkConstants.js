/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

const I18n = useI18nScope('custom_help_link')

const USER_TYPES = [
  {value: 'user', label: I18n.t('Everyone')},
  {value: 'student', label: I18n.t('Students')},
  {value: 'teacher', label: I18n.t('Teachers')},
  {value: 'admin', label: I18n.t('Admins')},
  {value: 'observer', label: I18n.t('Observers')},
  {value: 'unenrolled', label: I18n.t('Unenrolled')},
]

const DEFAULT_LINK = Object.freeze({
  text: '',
  subtext: '',
  url: '',
  available_to: USER_TYPES.map(type => type.value),
  is_default: 'false',
  index: 0,
  state: 'new',
  is_featured: false,
  is_new: false,
  feature_headline: '',
})

const NAME_PREFIX = 'account[custom_help_links]'

export default Object.freeze({
  USER_TYPES,
  DEFAULT_LINK,
  NAME_PREFIX,
})

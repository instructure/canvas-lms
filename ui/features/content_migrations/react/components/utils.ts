/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {FormMessage} from '@instructure/ui-form-field'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@instructure/moment-utils'

const I18n = useI18nScope('content_migrations_redesign')

export const humanReadableSize = (size: number): string => {
  const units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let i = 0
  while (size >= 1024) {
    size /= 1024
    ++i
  }
  return size.toFixed(1) + ' ' + units[i]
}

export const timeout = (delay: number) => {
  return new Promise(resolve => setTimeout(resolve, delay))
}

export const noFileSelectedFormMessage: FormMessage = {
  text: I18n.t('You must select a file to import content from'),
  type: 'error',
}

export const parseDateToISOString = (date: Date | null): string => {
  if (!date) {
    return ''
  }

  const adjustedDate = tz.parse(date)

  if (!adjustedDate) {
    return ''
  }

  return adjustedDate.toISOString()
}

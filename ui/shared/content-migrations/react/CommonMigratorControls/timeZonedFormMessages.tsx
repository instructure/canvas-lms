/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {Spacing} from '@instructure/emotion'
import type {FormMessage} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {datetimeString} from '@canvas/datetime/date-functions'
import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('content_migrations_redesign')

const generateMessageObject = (
  label: string,
  dateString: string,
  timezone?: string,
  margin?: Spacing,
): FormMessage => ({
  type: 'hint',
  text: (
    <View as="div" margin={margin}>
      <Text size="small">{`${label}: ${datetimeString(dateString, {timezone})}`}</Text>
    </View>
  ),
})

export const timeZonedFormMessages = (
  courseTimeZone: string,
  userTimeZone: string,
  dateString?: string,
): FormMessage[] => {
  if (!dateString || courseTimeZone === userTimeZone) {
    return []
  }
  return [
    generateMessageObject(I18n.t('Local'), dateString, userTimeZone, 'x-small none none'),
    generateMessageObject(I18n.t('Course'), dateString, courseTimeZone),
  ]
}

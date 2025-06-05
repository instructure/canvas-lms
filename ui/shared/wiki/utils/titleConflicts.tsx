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
import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {debounce} from '@instructure/debounce'
import type {FormMessage} from '@instructure/ui-form-field'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('wiki_pages')

type AvailabilityResponse = {
  conflict?: boolean
  errors?: Array<{message: string}>
}

export function conflictMessage(): FormMessage {
  const text = ENV.context_asset_string.startsWith('group')
    ? I18n.t(
        'There is already a page in this group with this title. Hitting save will create a duplicate.',
      )
    : I18n.t(
        'There is already a page in this course with this title. Hitting save will create a duplicate.',
      )
  return {
    type: 'hint',
    text: (
      <Flex as="div" alignItems="center" gap="x-small">
        <IconWarningSolid data-testid="warning-icon" color="warning" />
        <Text size="small">{text}</Text>
      </Flex>
    ),
  }
}

export function generateUrl(title: string, currentPageId?: string): string {
  const origin = ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
  if (!ENV.TITLE_AVAILABILITY_PATH) {
    throw new Error('Title availability path required')
  }
  const url = new URL(ENV.TITLE_AVAILABILITY_PATH, origin)
  url.searchParams.set('title', title)
  if (currentPageId) {
    url.searchParams.set('current_page_id', currentPageId)
  }
  return url.toString()
}

export async function fetchTitleAvailability(
  title: string,
  currentPageId?: string,
): Promise<boolean> {
  const response = await fetch(generateUrl(title, currentPageId))
  const {conflict, errors}: AvailabilityResponse = await response.json()
  if (response.ok) {
    return !!conflict
  } else {
    return Promise.reject(new Error(errors?.map(e => e.message).join('\n') ?? 'unknown'))
  }
}

export async function checkForTitleConflict(
  title: string,
  callback: (messages: FormMessage[]) => void,
  currentPageId?: string,
) {
  try {
    const conflict = await fetchTitleAvailability(title, currentPageId)
    conflict ? callback([conflictMessage()]) : callback([])
  } catch (error) {
    console.log(error)
    callback([])
  }
}

export const checkForTitleConflictDebounced = debounce(checkForTitleConflict, 500)

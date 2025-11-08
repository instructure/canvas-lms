/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {QueryFunctionContext} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AccessibilityScanResult} from '../types'

const I18n = createI18nScope('accessibility_scan')

export const accessibilityScanQuery = async ({
  signal,
  queryKey,
}: QueryFunctionContext): Promise<AccessibilityScanResult | undefined> => {
  const [, , courseId] = queryKey
  const fetchOpts = {signal}
  const path = `/courses/${courseId}/accessibility/course_scan`

  const {json} = await doFetchApi<AccessibilityScanResult>({path, fetchOpts})

  return json
}

export const createAccessibilityScanMutation = async ({
  courseId,
}: {
  courseId: string
}): Promise<AccessibilityScanResult> => {
  const {json, response} = await doFetchApi<AccessibilityScanResult>({
    path: `/courses/${courseId}/accessibility/course_scan`,
    method: 'POST',
  })

  if (!response.ok || json === undefined) {
    throw new Error(I18n.t('Failed to start a scan'))
  }

  return json
}

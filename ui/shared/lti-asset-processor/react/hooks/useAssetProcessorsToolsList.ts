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

import {useQuery, UseQueryResult} from '@tanstack/react-query'
import {useEffect} from 'react'

import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {AssetProcessorType} from '@canvas/lti/model/AssetProcessor'

const I18n = createI18nScope('asset_processors_selection')

const queryFn = async ({queryKey}: {queryKey: [string, number, string]}) => {
  const courseId = queryKey[1]
  const placement = queryKey[2]
  const {response, json} = await doFetchApi<LtiLaunchDefinition[]>({
    path: `/api/v1/courses/${courseId}/lti_apps/launch_definitions`,
    params: {'placements[]': placement, include_context_name: true},
  })
  if (!response.ok) {
    throw new Error(response.statusText)
  }
  return json
}

export function useAssetProcessorsToolsList(
  courseId: number,
  type: AssetProcessorType,
): UseQueryResult<LtiLaunchDefinition[], Error> {
  const res: UseQueryResult<LtiLaunchDefinition[], Error> = useQuery({
    queryKey: ['assetProcessors', courseId, type.toString()],
    queryFn,
  })

  const errorMsg = res.error?.message
  useEffect(() => {
    if (errorMsg) {
      showFlashError(I18n.t('Failed to load document processing apps: %{errorMsg}', {errorMsg}))
    }
  }, [errorMsg])

  return res
}

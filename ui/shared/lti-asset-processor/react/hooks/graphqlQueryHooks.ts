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

import {executeQuery} from '@canvas/graphql'
import {useQuery, useQueryClient} from '@tanstack/react-query'
import type {
  GqlTemplateStringType,
  GetLtiAssetProcessorsResult,
  GetLtiAssetReportsResult,
} from '@canvas/lti-asset-processor/shared-with-sg/dependenciesShims'
import {
  getLtiAssetProcessorsErrorMessage,
  GetLtiAssetProcessorsParams,
  LTI_ASSET_PROCESSORS_QUERY,
} from '@canvas/lti-asset-processor/shared-with-sg/replicated/queries/getLtiAssetProcessors'
import {
  getLtiAssetReportsErrorMessage,
  GetLtiAssetReportsParams,
  LTI_ASSET_REPORTS_QUERY,
} from '@canvas/lti-asset-processor/shared-with-sg/replicated/queries/getLtiAssetReports'
import {z} from 'zod'
import {
  ZGetLtiAssetProcessorsResult,
  ZGetLtiAssetReportsResult,
} from '@canvas/lti-asset-processor/model/LtiAssetReport'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

export const executeQueryAndValidate = async <T>(
  query: GqlTemplateStringType,
  params: any,
  errorMsg: string,
  schema: z.ZodType<T>,
): Promise<T> => {
  try {
    return schema.parse(await executeQuery<T>(query, params))
  } catch (e) {
    if (process.env.NODE_ENV !== 'test') {
      console.error(errorMsg, e)
    }
    showFlashAlert({message: errorMsg, type: 'error'})
    throw e
  }
}

export const getLtiAssetProcessors = (params: GetLtiAssetProcessorsParams) =>
  executeQueryAndValidate<GetLtiAssetProcessorsResult>(
    LTI_ASSET_PROCESSORS_QUERY,
    params,
    getLtiAssetProcessorsErrorMessage(),
    ZGetLtiAssetProcessorsResult,
  )

export function useLtiAssetProcessors(params: GetLtiAssetProcessorsParams) {
  return useQuery({
    queryKey: ['ltiAssetProcessors', params],
    queryFn: () => getLtiAssetProcessors(params),
    enabled: !!ENV.FEATURES?.lti_asset_processor,
  })
}

const getLtiAssetReports = (params: GetLtiAssetReportsParams) =>
  executeQueryAndValidate<GetLtiAssetReportsResult>(
    LTI_ASSET_REPORTS_QUERY,
    params,
    getLtiAssetReportsErrorMessage(),
    ZGetLtiAssetReportsResult,
  )

export function useLtiAssetReports(
  params: GetLtiAssetReportsParams,
  {cancel}: {cancel: boolean} = {cancel: false},
) {
  const queryKey = ['ltiAssetReports', params]
  const query = useQuery({
    queryKey,
    queryFn: () => getLtiAssetReports(params),
    enabled:
      ENV.FEATURES?.lti_asset_processor &&
      !cancel &&
      (!!params.studentUserId || !!params.studentAnonymousId),
  })
  const queryClient = useQueryClient()
  if (query.isFetching && cancel) {
    queryClient.cancelQueries({queryKey})
  }
  return query
}

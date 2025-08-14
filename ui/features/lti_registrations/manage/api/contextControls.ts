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

import {z} from 'zod'
import {LtiRegistrationId} from '../model/LtiRegistrationId'
import {LtiDeployment, ZLtiDeployment} from '../model/LtiDeployment'
import {ApiResult, parseFetchResult} from '../../common/lib/apiResult/ApiResult'
import {defaultFetchOptions} from '@canvas/util/xhr'
import {AccountId, ZAccountId} from '../model/AccountId'
import {LtiDeploymentId} from '../model/LtiDeploymentId'
import {
  LtiContextControl,
  LtiContextControlId,
  ZLtiContextControl,
} from '../model/LtiContextControl'
import {CourseId} from '../model/CourseId'

const baseUrl = (registrationId: LtiRegistrationId) => {
  const accountId = ZAccountId.parse(window.ENV.ACCOUNT_ID)

  return `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/controls`
}

/**
 * Fetches a list of Context controls for a given registration,
 * grouped by deployment.
 *
 * Provide either a `registrationId` or a `url` (gotten from links)
 * to fetch the controls.
 */
export type FetchControlsByDeployment = (
  options:
    | {
        registrationId: LtiRegistrationId
        pageSize?: number
      }
    | {
        url: string
      },
) => Promise<ApiResult<LtiDeployment[]>>

/**
 * Returns a list of LtiDeployments, each containing
 * a list of LtiContextControls in `context_controls`.
 */
export const fetchControlsByDeployment: FetchControlsByDeployment = options => {
  const url =
    'url' in options
      ? options.url
      : `${baseUrl(options.registrationId)}?per_page=${options.pageSize ?? 20}`
  return parseFetchResult(z.array(ZLtiDeployment))(fetch(url, defaultFetchOptions()))
}

export type DeleteContextControl = (
  registrationId: LtiRegistrationId,
  controlId: LtiContextControlId,
) => Promise<ApiResult<unknown>>

export const deleteContextControl: DeleteContextControl = (registrationId, controlId) =>
  parseFetchResult(z.unknown())(
    fetch(`${baseUrl(registrationId)}/${controlId}`, {
      ...defaultFetchOptions(),
      method: 'DELETE',
    }),
  )

export type UpdateContextControl = (
  registrationId: LtiRegistrationId,
  controlId: LtiContextControlId,
  available: boolean,
) => Promise<ApiResult<LtiContextControl>>
export const updateContextControl: UpdateContextControl = (registrationId, controlId, available) =>
  parseFetchResult(ZLtiContextControl)(
    fetch(`${baseUrl(registrationId)}/${controlId}`, {
      ...defaultFetchOptions(),
      method: 'PUT',
      body: JSON.stringify({available}),
      headers: {
        ...defaultFetchOptions().headers,
        'Content-Type': 'application/json',
      },
    }),
  )

export type ContextControlParameter = (
  | {
      account_id: AccountId
    }
  | {
      course_id: CourseId
    }
) & {
  deployment_id?: LtiDeploymentId
  available?: boolean
}

export const createContextControls = (options: {
  registrationId: LtiRegistrationId
  contextControls: Array<ContextControlParameter>
}) =>
  parseFetchResult(z.array(ZLtiContextControl))(
    fetch(`${baseUrl(options.registrationId)}/bulk`, {
      ...defaultFetchOptions(),
      method: 'POST',
      body: JSON.stringify(options.contextControls),
      headers: {
        ...defaultFetchOptions().headers,
        'Content-Type': 'application/json',
      },
    }),
  )

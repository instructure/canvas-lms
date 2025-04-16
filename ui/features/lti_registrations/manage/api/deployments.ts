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

import {defaultFetchOptions} from '@canvas/util/xhr'
import {parseFetchResult, type ApiResult} from '../../common/lib/apiResult/ApiResult'
import type {AccountId} from '../model/AccountId'
import {type LtiRegistrationId} from '../model/LtiRegistrationId'
import {LtiDeployment, ZLtiDeployment} from '../model/LtiDeployment'
import {z} from 'zod'
import {LtiDeploymentId} from '../model/LtiDeploymentId'

export type DeleteDeployment = (options: {
  registrationId: LtiRegistrationId
  accountId: AccountId
  deploymentId: LtiDeploymentId
}) => Promise<ApiResult<unknown>>

export const deleteDeployment: DeleteDeployment = options =>
  parseFetchResult(z.unknown())(
    fetch(
      `/api/v1/accounts/${options.accountId}/lti_registrations/${options.registrationId}/deployments/${options.deploymentId}`,
      {
        ...defaultFetchOptions(),
        method: 'DELETE',
      },
    ),
  )

export type FetchDeployments = (options: {
  registrationId: LtiRegistrationId
  accountId: AccountId
}) => Promise<ApiResult<LtiDeployment[]>>

export const fetchDeployments: FetchDeployments = options =>
  parseFetchResult(z.array(ZLtiDeployment))(
    fetch(
      `/api/v1/accounts/${options.accountId}/lti_registrations/${options.registrationId}/deployments`,
      {
        ...defaultFetchOptions(),
      },
    ),
  )

type CreateDeployment = (options: {
  registrationId: LtiRegistrationId
  accountId: AccountId
}) => Promise<ApiResult<LtiDeployment>>

export const createDeployment: CreateDeployment = options =>
  parseFetchResult(ZLtiDeployment)(
    fetch(
      `/api/v1/accounts/${options.accountId}/lti_registrations/${options.registrationId}/deployments`,
      {
        ...defaultFetchOptions(),
        method: 'POST',
      },
    ),
  )

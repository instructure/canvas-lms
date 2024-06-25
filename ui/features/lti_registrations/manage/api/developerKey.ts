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

import * as z from 'zod'
import type {AccountId} from '../model/AccountId'
import {parseFetchResult} from '../../common/lib/apiResult/ApiResult'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'
import {defaultFetchOptions} from '@canvas/util/xhr'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'

/**
 * Updates the workflow state of a developer key
 * @param accountId
 * @param developerKeyId
 * @param workflowState
 * @returns
 */
export const updateDeveloperKeyWorkflowState = (
  accountId: AccountId,
  developerKeyId: DeveloperKeyId,
  workflowState: 'on' | 'off'
) =>
  parseFetchResult(z.unknown())(
    fetch(
      `/api/v1/accounts/${accountId}/developer_keys/${developerKeyId}/developer_key_account_bindings`,
      {
        ...defaultFetchOptions(),
        method: 'POST',
        headers: {
          ...defaultFetchOptions().headers,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          developer_key_account_binding: {
            workflow_state: workflowState,
          },
        }),
      }
    )
  )

/**
 * Deletes a developer key by id
 * @param developerKeyId
 * @returns
 */
export const deleteDeveloperKey = (developerKeyId: DeveloperKeyId) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/developer_keys/${developerKeyId}`, {
      ...defaultFetchOptions(),
      method: 'DELETE',
    })
  )

export const updateAdminNickname = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  admin_nickname: string
) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`, {
      ...defaultFetchOptions(),
      method: 'PUT',
      headers: {
        ...defaultFetchOptions().headers,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        admin_nickname,
      }),
    })
  )

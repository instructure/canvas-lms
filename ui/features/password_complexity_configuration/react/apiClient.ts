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

import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import type {PasswordSettingsResponse} from './types'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

declare const ENV: GlobalEnv

export const deleteForbiddenWordsFile = async (attachmentId: number): Promise<void> => {
  try {
    const {status: passwordSettingsStatus, data: settingsResult} =
      await executeApiRequest<PasswordSettingsResponse>({
        path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/settings`,
        method: 'GET',
      })

    if (passwordSettingsStatus !== 200) {
      throw new Error('Failed to fetch current settings.')
    }

    const {status: fileStatus} = await executeApiRequest({
      path: `/api/v1/files/${attachmentId}`,
      method: 'DELETE',
    })

    if (fileStatus !== 200) {
      throw new Error('Failed to delete forbidden words file.')
    }

    const updatedPasswordPolicy = {
      account: {
        settings: {
          ...settingsResult,
        },
      },
    }
    delete updatedPasswordPolicy.account.settings.password_policy?.common_passwords_attachment_id
    const {status} = await executeApiRequest({
      path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/`,
      body: updatedPasswordPolicy,
      method: 'PUT',
    })
    if (status !== 200) {
      throw new Error('Failed to update password policy settings.')
    }
  } catch (error) {
    console.error('Error deleting forbidden words file:', error)
    throw error
  }
}

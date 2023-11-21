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
import axios from '@canvas/axios'

/**
 * Updates the workflow state of a developer key
 * @param contextId  The account id
 * @param developerKeyId
 * @param workflowState
 */
export const updateDeveloperKeyWorkflowState = (
  contextId: string,
  developerKeyId: string | number,
  workflowState: 'on' | 'off'
) =>
  axios.post(
    `/api/v1/accounts/${contextId}/developer_keys/${developerKeyId}/developer_key_account_bindings`,
    {
      developer_key_account_binding: {
        workflow_state: workflowState,
      },
    }
  )

/**
 * Deletes a developer key by id
 * @param developerKeyId
 * @returns
 */
export const deleteDeveloperKey = (developerKeyId: string | number) =>
  axios.delete(`/api/v1/developer_keys/${developerKeyId}`, {
    method: 'DELETE',
  })

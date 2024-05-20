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

import {useState} from 'react'
import {useMutation} from 'react-apollo'
import gql from 'graphql-tag'
import {ApiCallStatus} from '@canvas/do-fetch-api-effect/apiRequest'

const SET_OVERRIDE_STATUS_MUTATION = gql`
  mutation SetOverrideStatusMutation(
    $customGradeStatusId: ID
    $enrollmentId: ID!
    $gradingPeriodId: ID
  ) {
    setOverrideStatus(
      input: {
        customGradeStatusId: $customGradeStatusId
        enrollmentId: $enrollmentId
        gradingPeriodId: $gradingPeriodId
      }
    ) {
      errors {
        attribute
        message
      }
    }
  }
`

export const useFinalGradeOverrideCustomStatus = () => {
  const [saveCallStatus, setSaveCallStatus] = useState<ApiCallStatus>(ApiCallStatus.NOT_STARTED)
  const [setOverrideStatusMutation] = useMutation(SET_OVERRIDE_STATUS_MUTATION)

  const saveFinalOverrideCustomStatus = async (
    customGradeStatusId: string | null,
    enrollmentId: string,
    gradingPeriodId?: string | null
  ) => {
    setSaveCallStatus(ApiCallStatus.PENDING)
    try {
      const {data, errors} = await setOverrideStatusMutation({
        variables: {
          customGradeStatusId,
          enrollmentId,
          gradingPeriodId,
        },
      })

      if (errors || !data || data?.setOverrideStatus.errors?.length) {
        throw new Error('Failed to save final override custom status')
      }

      setSaveCallStatus(ApiCallStatus.COMPLETED)
    } catch (error) {
      setSaveCallStatus(ApiCallStatus.FAILED)
    }
  }

  return {
    saveFinalOverrideCustomStatus,
    saveCallStatus,
  }
}

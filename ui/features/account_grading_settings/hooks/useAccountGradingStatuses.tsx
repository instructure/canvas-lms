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

import {useEffect, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'
import {
  DELETE_CUSTOM_GRADING_STATUS_MUTATION,
  UPSERT_CUSTOM_GRADING_STATUS_MUTATION,
  UPSERT_STANDARD_GRADING_STATUS_MUTATION,
} from '../graphql/mutations/GradingStatusMutations'
import {ACCOUNT_GRADING_STATUS_QUERY} from '../graphql/queries/GradingStatusQueries'
import {
  CustomGradingStatusDeleteResponse,
  CustomGradingStatusUpsertResponse,
  StandardGradingStatusUpsertResponse,
} from '../types/accountStatusMutations'
import {AccountGradingStatusQueryResults} from '../types/accountStatusQueries'
import {
  mapCustomStatusQueryResults,
  mapStandardStatusQueryResults,
} from '../utils/accountStatusUtils'

export const useAccountGradingStatuses = (accountId: string) => {
  const [standardStatuses, setStandardStatuses] = useState<GradeStatus[]>([])
  const [customStatuses, setCustomStatuses] = useState<GradeStatus[]>([])
  const [isLoadingStatusError, setIsLoadingStatusError] = useState<boolean>(false)
  const [hasSaveCustomStatusError, setHasSaveCustomStatusError] = useState<boolean>(false)
  const [hasSaveStandardStatusError, setHasSaveStandardStatusError] = useState<boolean>(false)
  const [hasDeleteCustomStatusError, setHasDeleteCustomStatusError] = useState<boolean>(false)

  const [upsertStandardStatusMutation] = useMutation<StandardGradingStatusUpsertResponse>(
    UPSERT_STANDARD_GRADING_STATUS_MUTATION
  )
  const [upsertCustomStatusMutation] = useMutation<CustomGradingStatusUpsertResponse>(
    UPSERT_CUSTOM_GRADING_STATUS_MUTATION
  )
  const [deleteCustomStatusMutation] = useMutation<CustomGradingStatusDeleteResponse>(
    DELETE_CUSTOM_GRADING_STATUS_MUTATION
  )

  const {
    data: fetchStatusesData,
    error: fetchStatusesError,
    loading: loadingStatuses,
  } = useQuery<AccountGradingStatusQueryResults>(ACCOUNT_GRADING_STATUS_QUERY, {
    variables: {accountId},
    fetchPolicy: 'no-cache',
    skip: !accountId,
  })

  useEffect(() => {
    if (fetchStatusesError) {
      setIsLoadingStatusError(true)
      return
    }

    if (!fetchStatusesData?.account) {
      return
    }

    const {account} = fetchStatusesData
    const {customGradeStatusesConnection, standardGradeStatusesConnection} = account
    setCustomStatuses(mapCustomStatusQueryResults(customGradeStatusesConnection.nodes))
    setStandardStatuses(mapStandardStatusQueryResults(standardGradeStatusesConnection.nodes))
  }, [fetchStatusesData, fetchStatusesError])

  const saveStandardStatus = async (updatedStatus: GradeStatus) => {
    setHasSaveStandardStatusError(false)
    const {isNew, color, name, id} = updatedStatus

    const variables = {
      color,
      name,
      id: isNew ? undefined : id,
    }

    const {data, errors} = await upsertStandardStatusMutation({variables})

    if (errors || !data || data.upsertStandardGradeStatus.errors?.length) {
      setHasSaveStandardStatusError(true)
      return
    }

    const {
      upsertStandardGradeStatus: {standardGradeStatus: savedStatus},
    } = data

    setStandardStatuses(statuses => {
      const statusIndexToChange = statuses.findIndex(status =>
        isNew ? status.name === savedStatus.name : status.id === savedStatus.id
      )

      if (statusIndexToChange >= 0) {
        statuses[statusIndexToChange] = {...savedStatus, name}
      }
      return [...statuses]
    })
  }

  const saveCustomStatus = async (color: string, name: string, id?: string) => {
    setHasSaveCustomStatusError(false)
    const variables = {
      id,
      color,
      name,
    }
    const {data, errors} = await upsertCustomStatusMutation({variables})

    if (errors || !data || data?.upsertCustomGradeStatus.errors?.length) {
      setHasSaveCustomStatusError(true)
      return
    }

    const {
      upsertCustomGradeStatus: {customGradeStatus: savedStatus},
    } = data

    if (!id) {
      setCustomStatuses(statuses => [...statuses, {...savedStatus}])
    } else {
      setCustomStatuses(statuses => {
        const statusIndexToChange = statuses.findIndex(status => status.id === savedStatus.id)
        if (statusIndexToChange >= 0) {
          statuses[statusIndexToChange] = savedStatus
        }
        return [...statuses]
      })
    }
  }

  const removeCustomStatus = async (statusId: string) => {
    setHasDeleteCustomStatusError(false)
    const {data, errors} = await deleteCustomStatusMutation({
      variables: {
        id: statusId,
      },
    })

    if (errors || !data || data?.deleteCustomGradeStatus.errors?.length) {
      setHasDeleteCustomStatusError(true)
      return
    }
    setCustomStatuses(statuses => [...statuses.filter(status => status.id !== statusId)])
  }

  return {
    customStatuses,
    hasDeleteCustomStatusError,
    hasSaveCustomStatusError,
    hasSaveStandardStatusError,
    isLoadingStatusError,
    loadingStatuses,
    standardStatuses,
    removeCustomStatus,
    saveCustomStatus,
    saveStandardStatus,
  }
}

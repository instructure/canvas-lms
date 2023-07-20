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
import {useQuery} from 'react-apollo'
import {ACCOUNT_GRADING_STATUS_QUERY} from '../graphql/queries/GradingStatusQueries'
import {AccountGradingStatusQueryResults} from '../types/accountStatusQueries'
import {GradeStatus} from '../types/gradingStatus'
import {
  mapCustomStatusQueryResults,
  mapStandardStatusQueryResults,
} from '../utils/accountStatusUtils'

export const useAccountGradingStatuses = (accountId: string) => {
  const [standardStatuses, setStandardStatuses] = useState<GradeStatus[]>([])
  const [customStatuses, setCustomStatuses] = useState<GradeStatus[]>([])
  const [isLoadingStatusError, setIsLoadingStatusError] = useState<boolean>(false)

  const {
    data,
    error,
    loading: loadingStatuses,
  } = useQuery<AccountGradingStatusQueryResults>(ACCOUNT_GRADING_STATUS_QUERY, {
    variables: {accountId},
    fetchPolicy: 'no-cache',
    skip: !accountId,
  })

  const saveStatusChanges = (updatedStatus: GradeStatus) => {
    const {type} = updatedStatus
    const updateStatusState = type === 'standard' ? setStandardStatuses : setCustomStatuses

    updateStatusState(statuses => {
      const statusIndexToChange = statuses.findIndex(status => status.id === updatedStatus.id)
      if (statusIndexToChange >= 0) {
        statuses[statusIndexToChange] = updatedStatus
      }
      return [...statuses]
    })
  }

  const saveNewCustomStatus = (newStatus: GradeStatus) => {
    setCustomStatuses(statuses => [...statuses, newStatus])
  }

  const removeCustomStatus = (statusId: string) => {
    setCustomStatuses(statuses => [...statuses.filter(status => status.id !== statusId)])
  }

  useEffect(() => {
    if (error) {
      setIsLoadingStatusError(true)
      return
    }

    if (!data?.account) {
      return
    }

    const {customGradeStatusesConnection, standardGradeStatusesConnection} = data.account
    setCustomStatuses(mapCustomStatusQueryResults(customGradeStatusesConnection.nodes))
    setStandardStatuses(mapStandardStatusQueryResults(standardGradeStatusesConnection.nodes))
  }, [data, error])

  return {
    customStatuses,
    isLoadingStatusError,
    loadingStatuses,
    standardStatuses,
    saveNewCustomStatus,
    saveStatusChanges,
    removeCustomStatus,
  }
}

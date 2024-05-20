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
import type {GradeStatus, StandardStatusAllowedName} from '@canvas/grading/accountGradingStatus'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  DELETE_CUSTOM_GRADING_STATUS_MUTATION,
  UPSERT_CUSTOM_GRADING_STATUS_MUTATION,
  UPSERT_STANDARD_GRADING_STATUS_MUTATION,
} from '../graphql/mutations/GradingStatusMutations'
import {ACCOUNT_GRADING_STATUS_QUERY} from '../graphql/queries/GradingStatusQueries'
import type {
  CustomGradingStatusDeleteResponse,
  CustomGradingStatusUpsertResponse,
  StandardGradingStatusUpsertResponse,
} from '../types/accountStatusMutations'
import type {AccountGradingStatusQueryResults} from '../types/accountStatusQueries'
import {
  mapCustomStatusQueryResults,
  mapStandardStatusQueryResults,
  statusesTitleMap,
} from '../utils/accountStatusUtils'

const I18n = useI18nScope('account_grading_status')

export const useAccountGradingStatuses = (accountId: string, isExtendedStatusEnabled?: boolean) => {
  const [standardStatuses, setStandardStatuses] = useState<GradeStatus[]>([])
  const [customStatuses, setCustomStatuses] = useState<GradeStatus[]>([])
  const [isLoadingStatusError, setIsLoadingStatusError] = useState<boolean>(false)
  const [hasSaveCustomStatusError, setHasSaveCustomStatusError] = useState<boolean>(false)
  const [hasSaveStandardStatusError, setHasSaveStandardStatusError] = useState<boolean>(false)
  const [hasDeleteCustomStatusError, setHasDeleteCustomStatusError] = useState<boolean>(false)
  const [successMessage, setSuccessMessage] = useState<string>('')

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
    setStandardStatuses(
      mapStandardStatusQueryResults(standardGradeStatusesConnection.nodes, isExtendedStatusEnabled)
    )
  }, [fetchStatusesData, fetchStatusesError, isExtendedStatusEnabled])

  const saveStandardStatus = async (updatedStatus: GradeStatus) => {
    setHasSaveStandardStatusError(false)
    const {isNew, color, name, id} = updatedStatus

    const variables = {
      color,
      name,
      id: isNew ? undefined : id,
    }

    const statusName = statusesTitleMap[name as StandardStatusAllowedName]
    setSuccessMessage(I18n.t('Saving %{statusName} status', {statusName}))

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
    setSuccessMessage(I18n.t('%{statusName} status successfully saved', {statusName}))
  }

  const saveCustomStatus = async (color: string, name: string, id?: string) => {
    setHasSaveCustomStatusError(false)
    setSuccessMessage(I18n.t('Saving custom status %{name}', {name}))
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

    const {name: savedName} = savedStatus
    if (!id) {
      setCustomStatuses(statuses => [...statuses, {...savedStatus}])
      setSuccessMessage(I18n.t('Custom status %{savedName} added', {savedName}))
    } else {
      setCustomStatuses(statuses => {
        const statusIndexToChange = statuses.findIndex(status => status.id === savedStatus.id)
        if (statusIndexToChange >= 0) {
          statuses[statusIndexToChange] = savedStatus
        }
        return [...statuses]
      })
      setSuccessMessage(I18n.t('Custom status %{savedName} updated', {savedName}))
    }
  }

  const removeCustomStatus = async (statusId: string) => {
    const statusToRemove = customStatuses.find(status => status.id === statusId)
    const statusName = statusToRemove?.name ?? ''
    setSuccessMessage(I18n.t('Deleting custom status %{statusName}', {statusName}))
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
    setSuccessMessage(I18n.t('Successfully deleted custom status %{statusName}', {statusName}))
  }

  return {
    customStatuses,
    hasDeleteCustomStatusError,
    hasSaveCustomStatusError,
    hasSaveStandardStatusError,
    isLoadingStatusError,
    loadingStatuses,
    standardStatuses,
    successMessage,
    removeCustomStatus,
    saveCustomStatus,
    saveStandardStatus,
  }
}

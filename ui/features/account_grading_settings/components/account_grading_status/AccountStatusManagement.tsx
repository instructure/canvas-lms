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

import React, {useEffect, useState} from 'react'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {Grid} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {CustomStatusItem} from './CustomStatusItem'
import {StandardStatusItem} from './StandardStatusItem'
import {GradeStatus, GradeStatusType} from '../../types/gradingStatus'
import {CustomStatusNewItem} from './CustomStatusNewItem'
import {useAccountGradingStatuses} from '../../hooks/useAccountGradingStatuses'

const I18n = useI18nScope('account_grading_status')

const {Row: GridRow, Col: GridCol} = Grid as any

const TOTAL_ALLOWED_CUSTOM_STATUSES = 3

type AccountStatusManagementProps = {
  accountId: string
}
export const AccountStatusManagement = ({accountId}: AccountStatusManagementProps) => {
  const {
    customStatuses,
    isLoadingStatusError,
    loadingStatuses,
    standardStatuses,
    removeCustomStatus,
    saveNewCustomStatus,
    saveStatusChanges,
  } = useAccountGradingStatuses(accountId)
  const [openEditStatusId, setEditStatusId] = useState<string | undefined>(undefined)

  useEffect(() => {
    if (isLoadingStatusError) {
      showFlashError(I18n.t('Error loading grading statuses'))(new Error())
    }
  }, [isLoadingStatusError])

  const saveChanges = (updatedStatus: GradeStatus) => {
    saveStatusChanges(updatedStatus)
    setEditStatusId(undefined)
  }

  const remove = (statusId: string) => {
    setEditStatusId(undefined)
    removeCustomStatus(statusId)
  }

  const saveCustomStatus = (color: string, name: string) => {
    const newStatus: GradeStatus = {
      color,
      id: Math.floor(Math.random() * 1000).toString(),
      name,
      type: 'custom',
      isNew: true,
    }
    saveNewCustomStatus(newStatus)
    setEditStatusId(undefined)
  }

  const handleEditStatusToggle = (editStatusId: string) => {
    if (openEditStatusId === editStatusId) {
      setEditStatusId(undefined)
      return
    }

    setEditStatusId(editStatusId)
  }

  const getEditStatusId = (statusId: string, type: GradeStatusType) => {
    return `${type}-${statusId}`
  }

  const allowedCustomStatusAdditions = TOTAL_ALLOWED_CUSTOM_STATUSES - customStatuses.length

  if (loadingStatuses || isLoadingStatusError) {
    return <LoadingIndicator />
  }

  return (
    <Grid startAt="large" margin="small 0">
      <GridRow>
        <GridCol width={{large: 4}}>
          <Heading level="h2">
            <Text size="large">{I18n.t('Standard Statuses')}</Text>
          </Heading>
          {standardStatuses.map(gradeStatus => {
            const editStatusId = getEditStatusId(gradeStatus.id, 'standard')
            return (
              <StandardStatusItem
                key={`standard-status-${gradeStatus.id}`}
                gradeStatus={gradeStatus}
                handleEditSave={(newColor: string) => {
                  saveChanges({...gradeStatus, color: newColor})
                }}
                isEditOpen={openEditStatusId === editStatusId}
                handleEditStatusToggle={() => handleEditStatusToggle(editStatusId)}
              />
            )
          })}
        </GridCol>
        <GridCol>
          <Heading level="h2">
            <Text size="large">{I18n.t('Custom Statuses')}</Text>
          </Heading>
          {customStatuses.map(gradeStatus => {
            const editStatusId = getEditStatusId(gradeStatus.id, 'custom')
            return (
              <CustomStatusItem
                key={`custom-status-${gradeStatus.id}`}
                gradeStatus={gradeStatus}
                handleEditSave={(newColor: string, name: string) => {
                  saveChanges({...gradeStatus, color: newColor, name})
                }}
                handleStatusDelete={remove}
                isEditOpen={openEditStatusId === editStatusId}
                handleEditStatusToggle={() => handleEditStatusToggle(editStatusId)}
              />
            )
          })}
          {[...Array(allowedCustomStatusAdditions)].map((_, index) => {
            const editStatusId = getEditStatusId(index.toString(), 'new')
            return (
              <CustomStatusNewItem
                // eslint-disable-next-line react/no-array-index-key
                key={`custom-status-new-${index}-${allowedCustomStatusAdditions}`}
                handleSave={saveCustomStatus}
                index={index}
                isEditOpen={openEditStatusId === editStatusId}
                handleEditStatusToggle={() => handleEditStatusToggle(editStatusId)}
              />
            )
          })}
        </GridCol>
      </GridRow>
    </Grid>
  )
}

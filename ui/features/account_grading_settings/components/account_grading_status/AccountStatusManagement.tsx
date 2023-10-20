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
import type {GradeStatus, GradeStatusType} from '@canvas/grading/accountGradingStatus'
import {useScope as useI18nScope} from '@canvas/i18n'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import LoadingIndicator from '@canvas/loading-indicator'
import {Alert} from '@instructure/ui-alerts'
import {Grid} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {CustomStatusItem} from './CustomStatusItem'
import {StandardStatusItem} from './StandardStatusItem'
import {CustomStatusNewItem} from './CustomStatusNewItem'
import {useAccountGradingStatuses} from '../../hooks/useAccountGradingStatuses'

const I18n = useI18nScope('account_grading_status')

const {Row: GridRow, Col: GridCol} = Grid as any

const TOTAL_ALLOWED_CUSTOM_STATUSES = 3

export type AccountStatusManagementProps = {
  isRootAccount: boolean
  rootAccountId: string
  isExtendedStatusEnabled?: boolean
}
export const AccountStatusManagement = ({
  isRootAccount,
  rootAccountId,
  isExtendedStatusEnabled,
}: AccountStatusManagementProps) => {
  const {
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
  } = useAccountGradingStatuses(rootAccountId, isExtendedStatusEnabled)
  const [openEditStatusId, setEditStatusId] = useState<string | undefined>(undefined)

  useEffect(() => {
    if (isLoadingStatusError) {
      showFlashError(I18n.t('Error loading grading statuses'))(new Error())
    }
  }, [isLoadingStatusError])

  useEffect(() => {
    if (hasSaveCustomStatusError || hasSaveStandardStatusError) {
      const statusType = hasSaveCustomStatusError ? I18n.t('custom') : I18n.t('standard')
      const flashText = I18n.t('Error saving %{statusType} status', {statusType})
      showFlashError(flashText)(new Error())
    }
  }, [hasSaveCustomStatusError, hasSaveStandardStatusError])

  useEffect(() => {
    if (hasDeleteCustomStatusError) {
      showFlashError(I18n.t('Error deleting custom status'))(new Error())
    }
  }, [hasDeleteCustomStatusError])

  const handleSaveStandardStatus = (updatedStatus: GradeStatus) => {
    saveStandardStatus(updatedStatus)
    setEditStatusId(undefined)
  }

  const remove = (statusId: string) => {
    setEditStatusId(undefined)
    removeCustomStatus(statusId)
  }

  const handleSaveCustomStatus = (color: string, name: string, id?: string) => {
    saveCustomStatus(color, name, id)
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
    <View margin="small 0">
      {successMessage && (
        <Alert
          variant="success"
          screenReaderOnly={true}
          liveRegionPoliteness="polite"
          isLiveRegionAtomic={true}
          liveRegion={getLiveRegion}
        >
          {successMessage}
        </Alert>
      )}
      <Grid startAt="large">
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
                  editable={isRootAccount}
                  gradeStatus={gradeStatus}
                  handleEditSave={(newColor: string) => {
                    handleSaveStandardStatus({...gradeStatus, color: newColor})
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
                  editable={isRootAccount}
                  gradeStatus={gradeStatus}
                  handleEditSave={(newColor: string, name: string) => {
                    handleSaveCustomStatus(newColor, name, gradeStatus.id)
                  }}
                  handleStatusDelete={remove}
                  isEditOpen={openEditStatusId === editStatusId}
                  handleEditStatusToggle={() => handleEditStatusToggle(editStatusId)}
                />
              )
            })}
            {isRootAccount &&
              [...Array(allowedCustomStatusAdditions)].map((_, index) => {
                const editStatusId = getEditStatusId(index.toString(), 'new')
                return (
                  <CustomStatusNewItem
                    // eslint-disable-next-line react/no-array-index-key
                    key={`custom-status-new-${index}-${allowedCustomStatusAdditions}`}
                    handleSave={handleSaveCustomStatus}
                    index={index}
                    isEditOpen={openEditStatusId === editStatusId}
                    handleEditStatusToggle={() => handleEditStatusToggle(editStatusId)}
                  />
                )
              })}
          </GridCol>
        </GridRow>
      </Grid>
    </View>
  )
}

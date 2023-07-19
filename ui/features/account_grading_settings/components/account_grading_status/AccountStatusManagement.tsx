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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
// @ts-expect-error
import {Grid} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {CustomStatusItem} from './CustomStatusItem'
import {StandardStatusItem} from './StandardStatusItem'
import {GradeStatus, GradeStatusType} from '../../types/gradingStatus'
import {CustomStatusNewItem} from './CustomStatusNewItem'

const I18n = useI18nScope('account_grading_status')

const {Row: GridRow, Col: GridCol} = Grid as any

const TOTAL_ALLOWED_CUSTOM_STATUSES = 3

export const AccountStatusManagement = () => {
  const [standardStatuses, setStandardStatuses] = useState<GradeStatus[]>(fakeStandardStatuses)
  const [customStatuses, setCustomStatuses] = useState<GradeStatus[]>(fakeCustomStatuses)
  const [openEditStatusId, setEditStatusId] = useState<string | undefined>(undefined)

  const saveStatusChanges = (type: GradeStatusType, updatedStatus: GradeStatus) => {
    // TODO: hook for graphql mutation
    const updateStatusState = type === 'standard' ? setStandardStatuses : setCustomStatuses

    updateStatusState(statuses => {
      const statusIndexToChange = statuses.findIndex(status => status.id === updatedStatus.id)
      if (statusIndexToChange >= 0) {
        statuses[statusIndexToChange] = updatedStatus
      }
      return [...statuses]
    })

    setEditStatusId(undefined)
  }

  const removeCustomStatus = (statusId: string) => {
    // TODO: hook for graphql mutation
    setCustomStatuses(statuses => [...statuses.filter(status => status.id !== statusId)])
  }

  const saveCustomStatus = (color: string, name: string) => {
    // TODO: hook for graphql mutation
    const newStatus = {
      color,
      id: Math.floor(Math.random() * 1000).toString(),
      name,
    }
    setCustomStatuses(statuses => [...statuses, newStatus])
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
                  saveStatusChanges('standard', {...gradeStatus, color: newColor})
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
                  saveStatusChanges('custom', {...gradeStatus, color: newColor, name})
                }}
                handleStatusDelete={removeCustomStatus}
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
                key={`custom-status-new-${index}`}
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

const fakeStandardStatuses = [
  {
    id: '1',
    name: 'Late',
    color: '#E5F7E5',
    type: 'standard',
  },
  {
    id: '2',
    name: 'Missing',
    color: '#FFE8E5',
    type: 'standard',
  },
  {
    id: '3',
    name: 'Resubmitted',
    color: '#E9EDF5',
    type: 'standard',
  },
  {
    id: '4',
    name: 'Dropped',
    color: '#FEF0E5',
    type: 'standard',
  },
  {
    id: '5',
    name: 'Excused',
    color: '#FEF7E5',
    type: 'standard',
  },
  {
    id: '6',
    name: 'Extended',
    color: '#E5F3FC',
    type: 'standard',
  },
]

const fakeCustomStatuses = [
  {
    id: '1',
    name: 'No Presentado 1',
    color: '#F0E8EF',
    type: 'custom',
  },
  {
    id: '2',
    name: 'Super Long Custom Label Name',
    color: '#EEE',
    type: 'custom',
  },
]

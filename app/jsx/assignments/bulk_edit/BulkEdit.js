/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_bulk_edit'
import React, {useCallback, useEffect, useState} from 'react'
import {func, string} from 'prop-types'
import moment from 'moment-timezone'
import produce from 'immer'
import {List} from '@instructure/ui-elements'
import CanvasInlineAlert from 'jsx/shared/components/CanvasInlineAlert'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import BulkEditHeader from './BulkEditHeader'
import BulkEditTable from './BulkEditTable'
import MoveDatesModal from './MoveDatesModal'
import useSaveAssignments from './hooks/useSaveAssignments'
import useMonitorJobCompletion from './hooks/useMonitorJobCompletion'
import {originalDateField, canEditAll} from './utils'

BulkEdit.propTypes = {
  courseId: string.isRequired,
  onCancel: func.isRequired,
  onSave: func // for now, this is just informational that save has been clicked
}

BulkEdit.defaultProps = {
  onSave: () => {}
}

export default function BulkEdit({courseId, onCancel, onSave}) {
  const [assignments, setAssignments] = useState([])
  const [loadingError, setLoadingError] = useState(null)
  const [loading, setLoading] = useState(true)
  const [moveDatesModalOpen, setMoveDatesModalOpen] = useState(false)
  const {
    saveAssignments,
    startingSave,
    startingSaveError,
    progressUrl,
    setProgressUrl
  } = useSaveAssignments(courseId)
  const {jobCompletion, jobRunning, jobSuccess, jobErrors, setJobSuccess} = useMonitorJobCompletion(
    {
      progressUrl
    }
  )

  useFetchApi({
    success: setAssignments,
    error: setLoadingError,
    loading: setLoading,
    path: `/api/v1/courses/${courseId}/assignments/`,
    fetchAllPages: true,
    params: {
      per_page: 50,
      include: ['all_dates', 'can_edit'],
      order_by: 'due_at'
    }
  })

  useEffect(() => {
    function clearOriginalDates() {
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          const draftOverrides = draftAssignments.flatMap(assignment => assignment.all_dates)
          draftOverrides.forEach(draftOverride => {
            delete draftOverride[originalDateField('due_at')]
            delete draftOverride[originalDateField('unlock_at')]
            delete draftOverride[originalDateField('lock_at')]
          })
        })
      )
    }

    if (jobSuccess) clearOriginalDates()
  }, [jobSuccess])

  const setDateOnOverride = useCallback((override, dateFieldName, newDate) => {
    const originalField = originalDateField(dateFieldName)
    if (!override.hasOwnProperty(originalField)) {
      override[originalField] = override[dateFieldName]
    }
    override[dateFieldName] = newDate ? newDate.toISOString() : null
  }, [])

  const shiftDateOnOverride = useCallback(
    (override, dateFieldName, nDays) => {
      const currentDate = override[dateFieldName]
      if (currentDate) {
        const newDate = moment(currentDate)
          .add(nDays, 'days')
          .toDate()
        setDateOnOverride(override, dateFieldName, newDate)
      }
    },
    [setDateOnOverride]
  )

  const clearPreviousSave = useCallback(() => {
    // Clear anything from the previous save operation so those elements don't show anymore and so
    // the above effect doesn't try to clear the original dates.
    setJobSuccess(false)
    setProgressUrl(null)
  }, [setJobSuccess, setProgressUrl])

  const updateAssignmentDate = useCallback(
    ({dateKey, newDate, assignmentId, overrideId}) => {
      const isBaseOverride = !overrideId

      clearPreviousSave()
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          const assignment = draftAssignments.find(a => a.id === assignmentId)
          const override = assignment.all_dates.find(o =>
            isBaseOverride ? o.base : o.id === overrideId
          )
          setDateOnOverride(override, dateKey, newDate)
        })
      )
    },
    [clearPreviousSave, setDateOnOverride]
  )

  const setAssignmentSelected = useCallback((assignmentId, selected) => {
    setAssignments(currentAssignments =>
      produce(currentAssignments, draftAssignments => {
        const assignment = draftAssignments.find(a => a.id === assignmentId)
        assignment.selected = selected
      })
    )
  }, [])

  const selectAllAssignments = useCallback(selected => {
    setAssignments(currentAssignments =>
      produce(currentAssignments, draftAssignments => {
        draftAssignments.forEach(a => {
          if (canEditAll(a)) a.selected = selected
        })
      })
    )
  }, [])

  const handleSave = useCallback(() => {
    onSave()
    saveAssignments(assignments)
  }, [assignments, onSave, saveAssignments])

  const handleOpenBatchEdit = useCallback((value = true) => {
    setMoveDatesModalOpen(!!value)
  }, [])

  const handleBatchEditShift = useCallback(
    nDays => {
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          draftAssignments.forEach(draftAssignment => {
            if (draftAssignment.selected) {
              draftAssignment.all_dates.forEach(draftOverride => {
                shiftDateOnOverride(draftOverride, 'due_at', nDays)
                shiftDateOnOverride(draftOverride, 'unlock_at', nDays)
                shiftDateOnOverride(draftOverride, 'lock_at', nDays)
              })
            }
          })
        })
      )
      selectAllAssignments(false)
      setMoveDatesModalOpen(false)
    },
    [selectAllAssignments, shiftDateOnOverride]
  )
  const handleBatchEditRemove = useCallback(
    datesToRemove => {
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          draftAssignments.forEach(draftAssignment => {
            if (draftAssignment.selected) {
              draftAssignment.all_dates.forEach(draftOverride => {
                if (datesToRemove.includes('due_at'))
                  setDateOnOverride(draftOverride, 'due_at', null)
                if (datesToRemove.includes('unlock_at'))
                  setDateOnOverride(draftOverride, 'unlock_at', null)
                if (datesToRemove.includes('lock_at'))
                  setDateOnOverride(draftOverride, 'lock_at', null)
              })
            }
          })
        })
      )
      selectAllAssignments(false)
      setMoveDatesModalOpen(false)
    },
    [selectAllAssignments, setDateOnOverride]
  )

  function renderHeader() {
    const headerProps = {
      assignments,
      startingSave,
      jobRunning,
      jobCompletion,
      jobSuccess,
      onSave: handleSave,
      onCancel,
      onOpenBatchEdit: handleOpenBatchEdit
    }
    return <BulkEditHeader {...headerProps} />
  }

  function renderSaveSuccess() {
    if (jobSuccess) {
      return (
        <CanvasInlineAlert variant="success" liveAlert>
          {I18n.t('Assignment dates saved successfully.')}
        </CanvasInlineAlert>
      )
    }
  }

  function renderFetchError() {
    return (
      <CanvasInlineAlert variant="error" liveAlert>
        {I18n.t('There was an error retrieving assignment dates.')}
      </CanvasInlineAlert>
    )
  }

  function renderSaveError() {
    if (startingSaveError) {
      return (
        <CanvasInlineAlert variant="error" liveAlert>
          {I18n.t('Error starting save operation:')} {startingSaveError}
        </CanvasInlineAlert>
      )
    } else if (jobErrors) {
      return (
        <CanvasInlineAlert variant="error" liveAlert>
          {I18n.t('There were errors saving the assignment dates:')}
          <List>
            {jobErrors.map(error => {
              return <List.Item key={error}>{error}</List.Item>
            })}
          </List>
        </CanvasInlineAlert>
      )
    }
  }

  function renderMoveDatesModal() {
    return (
      <MoveDatesModal
        open={moveDatesModalOpen}
        onShiftDays={handleBatchEditShift}
        onRemoveDates={handleBatchEditRemove}
        onCancel={() => handleOpenBatchEdit(false)}
      />
    )
  }

  function renderBody() {
    if (loading) {
      return (
        <>
          <CanvasInlineAlert liveAlert screenReaderOnly>
            {I18n.t('Loading assignments')}
          </CanvasInlineAlert>
          <LoadingIndicator />
        </>
      )
    }

    if (loadingError) return renderFetchError()

    return (
      <>
        <CanvasInlineAlert liveAlert screenReaderOnly>
          {I18n.t('Assignments loaded')}
        </CanvasInlineAlert>
        <BulkEditTable
          assignments={assignments}
          updateAssignmentDate={updateAssignmentDate}
          setAssignmentSelected={setAssignmentSelected}
          selectAllAssignments={selectAllAssignments}
        />
      </>
    )
  }

  return (
    <>
      {renderMoveDatesModal()}
      {renderSaveSuccess()}
      {renderSaveError()}
      {renderHeader()}
      {renderBody()}
    </>
  )
}

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
import React, {useCallback, useEffect, useState, useMemo} from 'react'
import {func, string} from 'prop-types'
import moment from 'moment-timezone'
import produce from 'immer'
import {DateTime} from '@instructure/ui-i18n'
import CanvasInlineAlert from 'jsx/shared/components/CanvasInlineAlert'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import BulkEditDateSelect from './BulkEditDateSelect'
import BulkEditHeader from './BulkEditHeader'
import BulkEditTable from './BulkEditTable'
import MoveDatesModal from './MoveDatesModal'
import useSaveAssignments from './hooks/useSaveAssignments'
import useMonitorJobCompletion from './hooks/useMonitorJobCompletion'
import DateValidator from 'coffeescripts/util/DateValidator'
import GradingPeriodsAPI from 'coffeescripts/api/gradingPeriodsApi'
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
  const dateValidator = useMemo(
    () =>
      new DateValidator({
        date_range: ENV.VALID_DATE_RANGE || {
          start_at: {date: null, date_context: 'term'},
          end_at: {date: null, date_context: 'term'}
        },
        hasGradingPeriods: !!ENV.HAS_GRADING_PERIODS,
        gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods || []),
        userIsAdmin: (ENV.current_user_roles || []).includes('admin')
      }),
    []
  )
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

  useEffect(() => {
    function recordJobErrors(errors) {
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          draftAssignments.forEach(draftAssignment => {
            draftAssignment.all_dates.forEach(draftOverride => {
              let error
              if (draftOverride.base) {
                error = errors.find(
                  e => e.assignment_id == draftAssignment.id && !e.assignment_override_id // eslint-disable-line eqeqeq
                )
              } else {
                error = errors.find(e => e.assignment_override_id == draftOverride.id) // eslint-disable-line eqeqeq
              }
              if (error && error.errors) {
                draftOverride.errors = {}
                for (const dateKey in error.errors) {
                  draftOverride.errors[dateKey] = error.errors[dateKey][0].message
                }
              } else {
                delete draftOverride.errors
              }
            })
          })
        })
      )
    }
    if (jobErrors && !jobErrors.hasOwnProperty('message')) recordJobErrors(jobErrors)
  }, [jobErrors])

  const setDateOnOverride = useCallback(
    (override, dateFieldName, newDate) => {
      const currentDate = override[dateFieldName]
      const newDateISO = newDate?.toISOString() || null
      if (currentDate === newDateISO || moment(currentDate).isSame(moment(newDateISO))) return

      const originalField = originalDateField(dateFieldName)
      if (!override.hasOwnProperty(originalField)) {
        override[originalField] = override[dateFieldName]
      }
      override[dateFieldName] = newDateISO
      override.persisted = false
      override.errors = dateValidator.validateDatetimes(override)
    },
    [dateValidator]
  )

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

  const findOverride = useCallback((someAssignments, assignmentId, overrideId) => {
    const isBaseOverride = !overrideId
    const assignment = someAssignments.find(a => a.id === assignmentId)
    const override = assignment.all_dates.find(o => (isBaseOverride ? o.base : o.id === overrideId))
    return override
  }, [])

  const updateAssignmentDate = useCallback(
    ({dateKey, newDate, assignmentId, overrideId}) => {
      clearPreviousSave()
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          const override = findOverride(draftAssignments, assignmentId, overrideId)
          setDateOnOverride(override, dateKey, newDate)
        })
      )
    },
    [clearPreviousSave, findOverride, setDateOnOverride]
  )

  const clearOverrideEdits = useCallback(
    ({assignmentId, overrideId}) => {
      setAssignments(currentAssignments =>
        produce(currentAssignments, draftAssignments => {
          const override = findOverride(draftAssignments, assignmentId, overrideId)
          ;['due_at', 'unlock_at', 'lock_at'].forEach(dateField => {
            const originalField = originalDateField(dateField)
            if (override.hasOwnProperty(originalField)) {
              override[dateField] = override[originalField]
              delete override[originalField]
            }
          })
          delete override.errors
          delete override.persisted
        })
      )
    },
    [findOverride]
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

  const selectDateRange = useCallback((startDate, endDate) => {
    const timezone = ENV?.TIMEZONE || DateTime.browserTimeZone()
    const startMoment = moment.tz(startDate, timezone).startOf('day')
    const endMoment = moment.tz(endDate, timezone).endOf('day')
    setAssignments(currentAssignments =>
      produce(currentAssignments, draftAssignments => {
        draftAssignments.forEach(draftAssignment => {
          const shouldSelect = draftAssignment.all_dates.some(draftOverride =>
            ['due_at', 'lock_at', 'unlock_at'].some(dateField =>
              moment(draftOverride[dateField]).isBetween(startMoment, endMoment, null, '[]')
            )
          )
          draftAssignment.selected = shouldSelect
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
      setMoveDatesModalOpen(false)
    },
    [shiftDateOnOverride]
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
      setMoveDatesModalOpen(false)
    },
    [setDateOnOverride]
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

  function renderDateSelect() {
    return <BulkEditDateSelect selectDateRange={selectDateRange} />
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
          {jobErrors.hasOwnProperty('message')
            ? I18n.t('Error saving assignment dates: ') + jobErrors.message
            : I18n.t('Invalid dates were found. Please correct them and try again.')}
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
          clearOverrideEdits={clearOverrideEdits}
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
      {renderDateSelect()}
      {renderBody()}
    </>
  )
}

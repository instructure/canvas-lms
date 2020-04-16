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
import produce from 'immer'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-elements'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import CanvasInlineAlert from 'jsx/shared/components/CanvasInlineAlert'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import BulkEditTable from './BulkEditTable'
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

  function handleSave() {
    onSave()
    saveAssignments(assignments)
  }

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
          const originalField = originalDateField(dateKey)
          if (!override.hasOwnProperty(originalField)) override[originalField] = override[dateKey]
          override[dateKey] = newDate ? newDate.toISOString() : null
        })
      )
    },
    [clearPreviousSave]
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

  function anyAssignmentsEdited() {
    const overrides = assignments.flatMap(a => a.all_dates)
    return overrides.some(override =>
      [
        originalDateField('due_at'),
        originalDateField('unlock_at'),
        originalDateField('lock_at')
      ].some(originalField => override.hasOwnProperty(originalField))
    )
  }

  function renderProgressValue({valueNow}) {
    return <Text>{I18n.t('%{percent}%', {percent: valueNow})}</Text>
  }

  function renderHeader() {
    const selectedAssignmentsCount = assignments.filter(a => a.selected).length
    return (
      <Flex as="div">
        <Flex.Item shouldGrow>
          <h2>{I18n.t('Edit Assignment Dates')}</h2>
        </Flex.Item>
        {jobRunning && (
          <Flex.Item width="250px">
            <ProgressBar
              screenReaderLabel={I18n.t('Saving assignment dates progress')}
              valueNow={jobCompletion}
              renderValue={renderProgressValue}
            />
            <CanvasInlineAlert liveAlert screenReaderOnly variant="info">
              {I18n.t('Saving assignment dates progress: %{percent}%', {
                percent: jobCompletion
              })}
            </CanvasInlineAlert>
          </Flex.Item>
        )}
        {ENV.FEATURES.assignment_bulk_edit_phase_2 && (
          <Flex.Item margin="0 0 0 small">
            <Text>
              {I18n.t(
                {one: '%{count} assignment selected', other: '%{count} assignments selected'},
                {count: selectedAssignmentsCount}
              )}
            </Text>
          </Flex.Item>
        )}
        <Flex.Item>
          <Button margin="0 0 0 small" onClick={onCancel}>
            {jobSuccess ? I18n.t('Close') : I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            margin="0 0 0 small"
            variant="primary"
            interaction={
              startingSave || jobRunning || !anyAssignmentsEdited() ? 'disabled' : 'enabled'
            }
            onClick={handleSave}
          >
            {startingSave || jobRunning ? I18n.t('Saving...') : I18n.t('Save')}
          </Button>
        </Flex.Item>
      </Flex>
    )
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
      {renderSaveSuccess()}
      {renderSaveError()}
      {renderHeader()}
      {renderBody()}
    </>
  )
}

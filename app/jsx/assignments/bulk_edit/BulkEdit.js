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
import React, {useEffect, useState} from 'react'
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
import {originalDateField} from './utils'

BulkEdit.propTypes = {
  courseId: string.isRequired,
  onCancel: func.isRequired
}

export default function BulkEdit({courseId, onCancel}) {
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
      include: ['all_dates', 'can_edit'],
      order_by: 'due_at'
    }
  })

  useEffect(() => {
    function clearOriginalDates() {
      const nextAssignments = produce(assignments, draftAssignments => {
        const draftOverrides = draftAssignments.flatMap(assignment => assignment.all_dates)
        draftOverrides.forEach(draftOverride => {
          delete draftOverride[originalDateField('due_at')]
          delete draftOverride[originalDateField('unlock_at')]
          delete draftOverride[originalDateField('lock_at')]
        })
      })
      setAssignments(nextAssignments)
    }

    if (jobSuccess) clearOriginalDates()
  }, [assignments, jobSuccess])

  function handleSave() {
    saveAssignments(assignments)
  }

  function updateAssignment({dateKey, newDate, assignmentId, overrideId, base}) {
    // Clear anything from the previous save operation so those elements don't show anymore and so
    // the above effect doesn't try to clear the original dates.
    setJobSuccess(false)
    setProgressUrl(null)

    const nextAssignments = produce(assignments, draftAssignments => {
      const assignment = draftAssignments.find(a => a.id === assignmentId)
      const override = assignment.all_dates.find(o => (base ? o.base : o.id === overrideId))
      const originalField = originalDateField(dateKey)
      if (!override.hasOwnProperty(originalField)) override[originalField] = override[dateKey]
      override[dateKey] = newDate ? newDate.toISOString() : null
    })
    setAssignments(nextAssignments)
  }

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
    return (
      <Flex as="div">
        <Flex.Item shouldGrow>
          <h2>{I18n.t('Edit Assignment Dates')}</h2>
        </Flex.Item>
        <Flex.Item>
          {/* Inner Flex required to line up progress bar with buttons */}
          <Flex as="div">
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
            <Flex.Item>
              <Button margin="0 0 0 small" onClick={onCancel}>
                {I18n.t('Cancel')}
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
                {I18n.t('Save')}
              </Button>
            </Flex.Item>
          </Flex>
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
        <BulkEditTable assignments={assignments} updateAssignmentDate={updateAssignment} />
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

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
import React, {useState} from 'react'
import {func, string} from 'prop-types'
import produce from 'immer'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import BulkEditTable from './BulkEditTable'
import useSaveAssignments from './hooks/useSaveAssignments'
import {originalDateField} from './utils'

BulkEdit.propTypes = {
  courseId: string.isRequired,
  onCancel: func.isRequired
}

export default function BulkEdit({courseId, onCancel}) {
  const [assignments, setAssignments] = useState([])
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)
  const {saveAssignments, isSavingAssignments, savingAssignmentsErrors} = useSaveAssignments(
    courseId
  )

  useFetchApi({
    success: setAssignments,
    error: setError,
    loading: setLoading,
    path: `/api/v1/courses/${courseId}/assignments/`,
    fetchAllPages: true,
    params: {
      include: ['all_dates', 'can_edit'],
      order_by: 'due_at'
    }
  })

  function handleSave() {
    saveAssignments(assignments)
  }

  function updateAssignment({dateKey, newDate, assignmentId, overrideId, base}) {
    const nextAssignments = produce(assignments, draftAssignments => {
      const assignment = draftAssignments.find(a => a.id === assignmentId)
      const override = assignment.all_dates.find(o => (base ? o.base : o.id === overrideId))
      const originalField = originalDateField(dateKey)
      if (!override.hasOwnProperty(originalField)) override[originalField] = override[dateKey]
      override[dateKey] = newDate ? newDate.toISOString() : null
    })
    setAssignments(nextAssignments)
  }

  function renderHeader() {
    return (
      <Flex as="div">
        <Flex.Item shouldGrow>
          <h2>{I18n.t('Edit Dates')}</h2>
        </Flex.Item>
        <Flex.Item>
          <Button margin="0 0 0 small" onClick={onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            margin="0 0 0 small"
            variant="primary"
            disabled={isSavingAssignments}
            onClick={handleSave}
          >
            {I18n.t('Save')}
          </Button>
          {isSavingAssignments && <Spinner size="small" renderTitle={I18n.t('Saving Dates')} />}
        </Flex.Item>
      </Flex>
    )
  }

  function renderFetchError() {
    return (
      <Alert variant="error">{I18n.t('There was an error retrieving assignment dates.')}</Alert>
    )
  }

  function renderSaveError() {
    if (savingAssignmentsErrors.length) {
      return (
        <Alert variant="error">{I18n.t('There was an error saving the assignment dates.')}</Alert>
      )
    }
  }

  function renderBody() {
    if (loading) return <LoadingIndicator />
    if (error) return renderFetchError()
    return <BulkEditTable assignments={assignments} updateAssignmentDate={updateAssignment} />
  }

  return (
    <>
      {renderSaveError()}
      {renderHeader()}
      {renderBody()}
    </>
  )
}

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

import I18n from 'i18n!assignments_bulk_edit_use_save_assignment'
import {useCallback, useState} from 'react'
import doFetchApi from 'jsx/shared/effects/doFetchApi'
import {originalDateField} from '../utils'

const DATE_FIELDS = ['due_at', 'lock_at', 'unlock_at']

function extractEditedAssignmentsAndOverrides(assignments) {
  const editedAssignments = assignments.reduce((filteredAssignments, assignment) => {
    const editedOverrides = assignment.all_dates.reduce((filteredOverrides, override) => {
      if (!DATE_FIELDS.some(field => override.hasOwnProperty(originalDateField(field)))) {
        return filteredOverrides
      }

      const outputOverride = {id: override.id, base: override.base}
      // have to copy all the date fields because otherwise the API gives the missing ones their default value
      DATE_FIELDS.forEach(dateField => (outputOverride[dateField] = override[dateField]))
      return [...filteredOverrides, outputOverride]
    }, [])

    if (!editedOverrides.length) return filteredAssignments
    const outputAssignment = {id: assignment.id, all_dates: editedOverrides}
    return [...filteredAssignments, outputAssignment]
  }, [])

  return editedAssignments
}

async function extractErrorMessages(err) {
  if (!err.response) return [{message: err.message}]
  const errors = await err.response.json()
  if (errors.message) return [{message: errors.message}]
  if (Array.isArray(errors)) {
    return errors.map(error => {
      const messages = []
      if (error.errors.due_at) messages.push(error.errors.due_at.message)
      if (error.errors.unlock_at) messages.push(error.errors.unlock_at.message)
      if (error.errors.lock_at) messages.push(error.errors.lock_at.message)
      return {messages, assignmentId: error.assignment_id, overrideId: error.assignment_override_id}
    })
  }
  return [{message: I18n.t('An unknown error occurred')}]
}

export default function useSaveAssignments(courseId) {
  const [isSavingAssignments, setIsSavingAssignments] = useState(false)
  const [savingAssignmentsErrors, setSavingAssignmentsErrors] = useState([])

  const saveAssignments = useCallback(
    async assignments => {
      const editedAssignments = extractEditedAssignmentsAndOverrides(assignments)
      if (!editedAssignments.length) return

      setIsSavingAssignments(true)
      setSavingAssignmentsErrors([])
      try {
        await doFetchApi({
          path: `/api/v1/courses/${courseId}/assignments/bulk_update`,
          method: 'PUT',
          body: editedAssignments
        })
      } catch (err) {
        setSavingAssignmentsErrors(await extractErrorMessages(err))
      } finally {
        setIsSavingAssignments(false)
      }
    },
    [courseId]
  )

  return {
    saveAssignments,
    isSavingAssignments,
    setIsSavingAssignments,
    savingAssignmentsErrors,
    setSavingAssignmentsErrors
  }
}

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

import {useScope as useI18nScope} from '@canvas/i18n'
import {useCallback, useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {originalDateField, extractFetchErrorMessage} from '../utils'

const I18n = useI18nScope('assignments_bulk_edit_use_save_assignment')

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

export default function useSaveAssignments(courseId) {
  const [startingSave, setStartingSave] = useState(false)
  const [startingSaveError, setStartingSaveError] = useState(null)
  const [progressUrl, setProgressUrl] = useState(null)

  const saveAssignments = useCallback(
    async assignments => {
      const editedAssignments = extractEditedAssignmentsAndOverrides(assignments)
      if (!editedAssignments.length) return

      setStartingSave(true)
      setStartingSaveError(null)
      try {
        const {json} = await doFetchApi({
          path: `/api/v1/courses/${courseId}/assignments/bulk_update`,
          method: 'PUT',
          body: editedAssignments,
        })
        setProgressUrl(json.url)
      } catch (err) {
        setStartingSaveError(
          await extractFetchErrorMessage(
            err,
            I18n.t('There was an error starting the save assignment dates job')
          )
        )
      } finally {
        setStartingSave(false)
      }
    },
    [courseId]
  )

  return {
    saveAssignments,
    startingSave,
    setStartingSave,
    startingSaveError,
    setStartingSaveError,
    progressUrl,
    setProgressUrl,
  }
}

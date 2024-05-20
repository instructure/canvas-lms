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

import {useScope as useI18nScope} from '@canvas/i18n'
import {useEffect, useState} from 'react'
import {ApiCallStatus, type CustomColumnDatum} from '../../types'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

const I18n = useI18nScope('enhanced_individual_gradebook_submit_score')

type NotesMap = {
  [userId: string]: string
}

export const useGradebookNotes = (
  studentNotesColumnId?: string | null,
  getCustomColumnsUrl?: string | null,
  getCustomColumnDataUrl?: string | null,
  updateCustomColumnDataUrl?: string | null
) => {
  const [submitNotesStatus, setSubmitNotesStatus] = useState<ApiCallStatus>(
    ApiCallStatus.NOT_STARTED
  )
  const [getNotesStatus, setGetNotesStatus] = useState<ApiCallStatus>(ApiCallStatus.NOT_STARTED)
  const [submitNotesError, setSubmitNotesError] = useState<string>('')
  const [studentNotes, setStudentNotes] = useState<NotesMap>({})
  useEffect(() => {
    const fetchNotes = async () => {
      if (
        !studentNotesColumnId ||
        !getCustomColumnsUrl ||
        !getCustomColumnDataUrl ||
        getNotesStatus === ApiCallStatus.COMPLETED ||
        getNotesStatus === ApiCallStatus.PENDING
      ) {
        return
      }
      setGetNotesStatus(ApiCallStatus.PENDING)
      const notesMap: NotesMap = {}
      let path: string = getCustomColumnDataUrl.replace(':id', studentNotesColumnId)
      while (path) {
        // eslint-disable-next-line no-await-in-loop
        const {data, link} = await executeApiRequest<CustomColumnDatum[]>({
          method: 'GET',
          path,
        })
        data.forEach((note: CustomColumnDatum) => {
          notesMap[note.user_id] = note.content
        })
        if (!link?.next?.url) {
          break
        }
        path = link?.next?.url
      }
      setGetNotesStatus(ApiCallStatus.COMPLETED)
      setStudentNotes(notesMap)
    }
    fetchNotes()
  }, [
    getCustomColumnsUrl,
    getCustomColumnDataUrl,
    studentNotesColumnId,
    studentNotes,
    getNotesStatus,
  ])

  const submit = async (notes: string, studentId: string) => {
    if (studentNotes[studentId] === notes) {
      return
    }
    if (!updateCustomColumnDataUrl || !studentNotesColumnId) {
      setSubmitNotesError(I18n.t('Missing required parameters'))
      setSubmitNotesStatus(ApiCallStatus.FAILED)
      return
    }
    setSubmitNotesStatus(ApiCallStatus.PENDING)
    const {status} = await executeApiRequest({
      method: 'PUT',
      path: updateCustomColumnDataUrl
        .replace(':id', studentNotesColumnId)
        .replace(':user_id', studentId),
      body: {
        column_data: {
          content: notes,
        },
      },
    })
    if (status !== 200) {
      setSubmitNotesError(I18n.t('Request failed with status %{status}', {status}))
      setSubmitNotesStatus(ApiCallStatus.FAILED)
      return
    }
    setSubmitNotesStatus(ApiCallStatus.COMPLETED)
    setStudentNotes(prevStudentNotes => {
      return {...prevStudentNotes, [studentId]: notes}
    })
  }

  return {
    submitNotesError,
    submitNotesStatus,
    getNotesStatus,
    studentNotes,
    submit,
  }
}

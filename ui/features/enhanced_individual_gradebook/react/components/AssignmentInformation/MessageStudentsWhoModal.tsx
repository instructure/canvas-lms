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

import React, {useMemo} from 'react'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import MessageStudentsWhoDialog, {
  type SendMessageArgs,
  type Student,
} from '@canvas/message-students-dialog/react/MessageStudentsWhoDialog'
import type {CamelizedAssignment} from '@canvas/grading/grading.d'
import type {
  AssignmentConnection,
  GradebookOptions,
  SortableStudent,
  SubmissionConnection,
} from '../../../types'
import MessageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'

const I18n = useI18nScope('enhanced_individual_gradebook')

type MessageStudentsWhoModalProps = {
  assignment: AssignmentConnection
  students: SortableStudent[]
  submissions: SubmissionConnection[]
  gradebookOptions: GradebookOptions
  isOpen: boolean
  onClose: () => void
}
export default function MessageStudentsWhoModal({
  assignment,
  gradebookOptions,
  students,
  submissions,
  isOpen,
  onClose,
}: MessageStudentsWhoModalProps) {
  const {userId} = gradebookOptions

  const messageWhoAssignment: CamelizedAssignment = {
    ...assignment,
    muted: false,
  }

  const submissionMap = useMemo(() => {
    return submissions.reduce((acc, submission) => {
      acc[submission.userId] = submission
      return acc
    }, {} as Record<string, SubmissionConnection>)
  }, [submissions])

  const studentsWithSubmissionDetails = useMemo(() => {
    return students.reduce((filteredStudents, currentStudent) => {
      const submission = submissionMap[currentStudent.id]

      if (!submission) return filteredStudents

      filteredStudents.push({
        ...currentStudent,
        submittedAt: submission?.submittedAt,
        grade: submission?.grade,
        redoRequest: submission?.redoRequest,
        score: submission?.score,
        excused: submission?.excused,
      })

      return filteredStudents
    }, [] as Student[])
  }, [students, submissionMap])

  const onSendMessage = async (messageArgs: SendMessageArgs) => {
    const errorMessage = 'Message failed to send'
    try {
      const {status} = await MessageStudentsWhoHelper.sendMessageStudentsWho(
        messageArgs.recipientsIds,
        messageArgs.subject,
        messageArgs.body,
        `course_${assignment.courseId}`,
        messageArgs.mediaFile,
        messageArgs.attachmentIds
      )
      if (status === 202) {
        showFlashSuccess(I18n.t('Your message was sent!'))()
        onClose()
      } else {
        throw new Error(errorMessage)
      }
    } catch (error) {
      showFlashError(I18n.t('There was a problem sending your message.'))(
        new Error(I18n.t('%{errorMessage}', {errorMessage}))
      )
    }
  }

  if (!isOpen || !userId) return null

  return (
    <MessageStudentsWhoDialog
      assignment={messageWhoAssignment}
      students={studentsWithSubmissionDetails}
      onClose={onClose}
      onSend={onSendMessage}
      userId={userId}
      messageAttachmentUploadFolderId=""
    />
  )
}

/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Outcome, Student, StudentRollupData} from '@canvas/outcomes/react/types/rollup'

import MessageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useStudentMasteryScores} from '@canvas/outcomes/react/hooks/useStudentMasteryScores'
import MessageStudentsWhoDialog from '@instructure/outcomes-ui/es/components/Gradebook/dialogs/MessageStudentsWhoDialog'
import {StudentPopover} from '@instructure/outcomes-ui/es/components/Gradebook/popovers/StudentPopover'
import {showFlashError, showFlashSuccess} from '@instructure/platform-alerts'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React, {useCallback, useMemo, useState} from 'react'
import {useLmgbUserDetails} from '../../hooks/useLmgbUserDetails'

const I18n = createI18nScope('LearningMasteryGradebook')
const t = I18n.t.bind(I18n)

type MSWStudent = {
  id: string
  name: string
  sortableName: string
  submittedAt: null | Date
  workflowState: string
}

type SendMessageArgs = {
  attachmentIds?: string[]
  recipientsIds: string[]
  subject: string
  body: string
  mediaFile?: {id: string; type: string}
}

export interface StudentCellPopoverProps {
  student: Student
  studentName: string
  studentGradesUrl: string
  courseId: string
  outcomes?: Outcome[]
  rollups?: StudentRollupData[]
}

export const StudentCellPopover: React.FC<StudentCellPopoverProps> = ({
  student,
  studentName,
  studentGradesUrl,
  courseId,
  outcomes,
  rollups,
}) => {
  const [isShowingContent, setIsShowingContent] = useState(false)
  const [isMessageModalOpen, setIsMessageModalOpen] = useState(false)

  const {
    data: userDetails,
    isLoading,
    error: queryError,
  } = useLmgbUserDetails({
    courseId,
    studentId: String(student.id),
    enabled: isShowingContent,
  })

  const error = queryError ? t('Failed to load user details') : null

  const scores = useStudentMasteryScores({
    student: userDetails ? student : null,
    outcomes: outcomes || [],
    rollups: rollups || [],
  })

  const mswStudents = useMemo<MSWStudent[]>(
    () => [
      {
        id: student.id,
        name: studentName,
        sortableName: student.sortable_name,
        submittedAt: null,
        workflowState: 'graded',
      },
    ],
    [student.id, studentName, student.sortable_name],
  )

  const handleSendMessage = useCallback(
    ({recipientsIds, subject, body, mediaFile, attachmentIds}: SendMessageArgs) => {
      MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        `course_${courseId}`,
        mediaFile,
        attachmentIds,
      )
        .then(() => showFlashSuccess(t('Message sent successfully'))())
        .catch(() => showFlashError(t('Failed to send message'))())
    },
    [courseId],
  )

  const renderLastLogin = () => {
    let dateText: string = t('Never')
    if (userDetails?.user.last_login) {
      const isToday =
        new Date(userDetails.user.last_login).toDateString() === new Date().toDateString()
      dateText = new Date(userDetails.user.last_login).toLocaleString(undefined, {
        dateStyle: isToday ? undefined : 'medium',
        timeStyle: isToday ? 'short' : undefined,
      })
    }
    return <Text size="legend" color="secondary">{`${t('Last Login')}: ${dateText}`}</Text>
  }

  const masteryScoresOverride = scores ? (
    <Flex direction="column">
      <Flex.Item>
        <Flex direction="row" alignItems="center" gap="x-small" margin="small none">
          <Flex.Item width="1.7rem">
            <Img width="100%" height="100%" src={scores.averageIconURL} />
          </Flex.Item>
          <Flex.Item>
            <Text size="small">
              {`${scores.grossAverage ? scores.grossAverage.toFixed(1) + ' ' : ''}${scores.averageText}`}
            </Text>
          </Flex.Item>
        </Flex>
        <Flex gap="small" margin="small small small none">
          {scores.buckets &&
            Object.values(scores.buckets)
              .reverse()
              .map(bucket => (
                <Flex key={bucket.name} direction="row" alignItems="center" gap="xx-small">
                  <Flex.Item width="1.4rem">
                    <Img width="100%" height="100%" src={bucket.iconURL} />
                  </Flex.Item>
                  <Flex.Item>
                    <ScreenReaderContent>{`${bucket.name} ${bucket.count}`}</ScreenReaderContent>
                    <Text size="medium" aria-hidden="true">
                      {bucket.count}
                    </Text>
                  </Flex.Item>
                </Flex>
              ))}
        </Flex>
      </Flex.Item>
      <Flex.Item>{renderLastLogin()}</Flex.Item>
    </Flex>
  ) : undefined

  const actionsOverride = (
    <>
      {isMessageModalOpen && (
        <MessageStudentsWhoDialog
          onClose={() => setIsMessageModalOpen(false)}
          students={mswStudents}
          onSend={handleSendMessage}
          userId={ENV.current_user_id ?? ''}
        />
      )}
      <Flex direction="row" justifyItems="center">
        <Flex.Item>
          <Link onClick={() => setIsMessageModalOpen(true)}>
            <Text size="small">{t('Message')}</Text>
          </Link>
        </Flex.Item>
        <View
          as="div"
          margin="none small none small"
          borderWidth="none small none none"
          width="0px"
          height="1.4rem"
        />
        <Flex.Item>
          <Link href={studentGradesUrl}>
            <Text size="small">{t('View Mastery Report')}</Text>
          </Link>
        </Flex.Item>
      </Flex>
    </>
  )

  return (
    <StudentPopover
      studentName={studentName}
      avatarUrl={student.avatar_url}
      description={userDetails?.course.name}
      metadata={userDetails?.user.sections.map(s => s.name).join(', ')}
      masteryScoresOverride={masteryScoresOverride}
      actionsOverride={actionsOverride}
      isLoading={isLoading}
      error={error}
      onShowingContentChange={setIsShowingContent}
    />
  )
}

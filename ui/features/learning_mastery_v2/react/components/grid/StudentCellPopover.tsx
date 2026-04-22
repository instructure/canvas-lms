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

import {Outcome, StudentRollupData, Student} from '@canvas/outcomes/react/types/rollup'

import React, {useState} from 'react'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import MessageStudents from '@canvas/message-students-modal'
import {useStudentMasteryScores} from '@canvas/outcomes/react/hooks/useStudentMasteryScores'
import {useLmgbUserDetails} from '../../hooks/useLmgbUserDetails'
import {StudentPopover} from '@instructure/outcomes-ui/es/components/Gradebook/popovers/StudentPopover'

const I18n = createI18nScope('LearningMasteryGradebook')
const t = I18n.t.bind(I18n)

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
        <MessageStudents
          contextCode={`course_${courseId}`}
          onRequestClose={() => setIsMessageModalOpen(false)}
          open={isMessageModalOpen}
          bulkMessage={false}
          groupConversation={false}
          recipients={[
            {
              id: student.id,
              displayName: studentName,
            },
          ]}
          title={t('Send a message')}
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

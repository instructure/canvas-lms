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

import {Outcome, StudentRollupData, Student} from '../../types/rollup'

import React, {useState, useMemo} from 'react'
import {Link} from '@instructure/ui-link'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Popover} from '@instructure/ui-popover'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Avatar} from '@instructure/ui-avatar'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import MessageStudents from '@canvas/message-students-modal'
import {Img} from '@instructure/ui-img'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useLmgbUserDetails} from '../../hooks/useLmgbUserDetails'

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

interface ScoreCalcResult {
  masteryRelativeAverage: number | null
  grossAverage: number | null
  averageIconURL: string
  averageText: string
  buckets: {
    [key: string]: {
      name: string
      iconURL: string
      count: number
    }
  }
}

export const pickBucketForScore = (score: number | null, buckets: ScoreCalcResult['buckets']) => {
  if (score === null) return buckets.no_evidence
  if (score > 0) return buckets.exceeds_mastery
  if (score === 0) return buckets.mastery
  if (score < -1) return buckets.remediation
  if (score < 0) return buckets.near_mastery
  return buckets.no_evidence
}

export const calculateScores = (
  outcomes: Outcome[],
  rollups: StudentRollupData[],
  student: Student,
) => {
  const result: ScoreCalcResult = {
    masteryRelativeAverage: null,
    grossAverage: null,
    averageIconURL: '',
    averageText: '',
    buckets: {
      no_evidence: {name: t('No Evidence'), iconURL: '/images/outcomes/no_evidence.svg', count: 0},
      remediation: {name: t('Remediation'), iconURL: '/images/outcomes/remediation.svg', count: 0},
      near_mastery: {
        name: t('Near Mastery'),
        iconURL: '/images/outcomes/near_mastery.svg',
        count: 0,
      },
      mastery: {name: t('Mastery'), iconURL: '/images/outcomes/mastery.svg', count: 0},
      exceeds_mastery: {
        name: t('Exceeds Mastery'),
        iconURL: '/images/outcomes/exceeds_mastery.svg',
        count: 0,
      },
    },
  }

  const userOutcomeRollups = rollups?.find(r => r.studentId === student.id)?.outcomeRollups || []

  if (outcomes?.length)
    result.buckets.no_evidence.count = outcomes.length - userOutcomeRollups.length

  let grossTotalScore = 0
  let masteryRelativeTotalScore = 0
  let withResultsCount = 0

  userOutcomeRollups.forEach(rollup => {
    const outcome = outcomes?.find(o => o.id === rollup.outcomeId)
    if (!outcome) return
    const masteryScore = rollup.rating.points - outcome.mastery_points
    const bucket = pickBucketForScore(masteryScore, result.buckets)
    bucket.count++
    masteryRelativeTotalScore += masteryScore
    grossTotalScore += rollup.rating.points
    withResultsCount++
  })

  if (withResultsCount > 0) {
    result.masteryRelativeAverage = masteryRelativeTotalScore / withResultsCount
    result.grossAverage = grossTotalScore / withResultsCount
  }

  const averageBucket = pickBucketForScore(result.masteryRelativeAverage, result.buckets)
  result.averageIconURL = averageBucket.iconURL
  result.averageText = averageBucket.name

  return result
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

  const scores = useMemo(() => {
    if (!userDetails) return null
    return calculateScores(outcomes || [], rollups || [], student)
  }, [userDetails, outcomes, rollups, student])

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

  const ResultIcon: React.FC<{url: string; alt: string}> = ({url, alt}) => {
    return (
      <>
        <Img width="100%" height="100%" src={url} alt={alt} />
        <ScreenReaderContent>{alt}</ScreenReaderContent>
      </>
    )
  }

  const renderScores = () => (
    <View>
      <Flex direction="row" alignItems="center" gap="x-small" margin="small none">
        <Flex.Item width="1.7rem">
          <ResultIcon url={scores?.averageIconURL || ''} alt={scores?.averageText || ''} />
        </Flex.Item>
        <Flex.Item>
          {scores?.grossAverage && <Text>{`${scores.grossAverage.toFixed(1)} `}</Text>}
          <Text size="small">{scores?.averageText}</Text>
        </Flex.Item>
      </Flex>
      <Flex gap="small" margin="small small small none">
        {scores?.buckets &&
          Object.values(scores.buckets)
            .reverse()
            .map(bucket => (
              <Flex key={bucket.name} direction="row" alignItems="center" gap="xx-small">
                <Flex.Item width="1.4rem">
                  <ResultIcon url={bucket.iconURL} alt={bucket.name} />
                </Flex.Item>
                <Flex.Item>
                  <Text size="medium">{bucket.count}</Text>
                </Flex.Item>
              </Flex>
            ))}
      </Flex>
    </View>
  )

  const renderPopoverContent = () => (
    <View padding="small" display="block" maxWidth="480px" minWidth="300px" minHeight="200px">
      {isLoading && (
        <View as="div" textAlign="center" margin="medium none">
          <Spinner renderTitle={t('Loading user details')} size="small" />
        </View>
      )}
      {error && (
        <View as="div" margin="small none">
          <Text>{error}</Text>
        </View>
      )}
      {userDetails && (
        <View as="div">
          <Flex gap="small" alignItems="start">
            <Flex.Item>
              <Avatar
                alt={studentName}
                as="div"
                size="large"
                name={studentName}
                src={student.avatar_url}
                data-testid="lmgb-student-popover-avatar"
              />
            </Flex.Item>
            <Flex.Item>
              <View display="block" maxWidth={'320px'}>
                <View>
                  <Text size="content" weight="bold">
                    <TruncateText>{studentName}</TruncateText>
                  </Text>
                </View>
                <View>
                  <Text size="contentSmall">
                    <TruncateText>{userDetails.course.name}</TruncateText>
                  </Text>
                </View>
                {userDetails.user.sections.length > 0 && (
                  <View>
                    <Text size="legend">
                      <TruncateText>
                        {userDetails.user.sections.map(section => section.name).join(', ')}
                      </TruncateText>
                    </Text>
                  </View>
                )}
              </View>
              {renderScores()}
              {renderLastLogin()}
            </Flex.Item>
          </Flex>
          <View
            as="div"
            margin="small none x-small none"
            borderWidth="small none none none"
            height="0px"
          />
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
        </View>
      )}
    </View>
  )

  const renderCloseButton = () => (
    <CloseButton
      placement="end"
      offset="small"
      onClick={() => setIsShowingContent(false)}
      screenReaderLabel={t('Close')}
    />
  )

  return (
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
      <Popover
        renderTrigger={
          <Link isWithinText={false} onClick={() => {}} data-testid="student-cell-link">
            <TruncateText>{studentName}</TruncateText>
          </Link>
        }
        isShowingContent={isShowingContent}
        onShowContent={() => {
          setIsShowingContent(true)
        }}
        onHideContent={() => {
          setIsShowingContent(false)
        }}
        on="click"
        screenReaderLabel={`${t('Student Details for')} ${studentName}`}
        shouldContainFocus
        shouldReturnFocus
        shouldCloseOnDocumentClick
        offsetY="16px"
      >
        <View padding="small" display="block">
          {renderCloseButton()}
        </View>
        {renderPopoverContent()}
      </Popover>
    </>
  )
}

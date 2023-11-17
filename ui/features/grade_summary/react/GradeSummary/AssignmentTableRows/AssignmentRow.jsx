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

import React from 'react'
import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'

import useStore from '../../stores'

import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
import {
  IconCommentLine,
  IconMutedLine,
  IconAnalyticsLine,
  IconRubricLine,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

import WhatIfGrade from '../WhatIfGrade'
import {getDisplayStatus, getDisplayScore, submissionCommentsPresent} from '../utils'

const I18n = useI18nScope('grade_summary')

const getSubmissionCommentsTrayProps = assignmentId => {
  const matchingSubmission = ENV.submissions.find(x => x.assignment_id === assignmentId)
  const {submission_comments, assignment_url: assignmentUrl} = matchingSubmission
  const attempts = submission_comments?.reduce((attemptsMessages, comment) => {
    const currentAttempt = comment.attempt < 1 ? 1 : comment.attempt

    if (attemptsMessages[currentAttempt]) {
      attemptsMessages[currentAttempt].push(comment)
    } else {
      attemptsMessages[currentAttempt] = [comment]
    }

    return attemptsMessages
  }, {})
  return {
    attempts,
    assignmentUrl,
  }
}

const handleSubmissionsCommentTray = assignmentId => {
  const {submissionTrayAssignmentId, submissionTrayOpen} = useStore.getState()

  if (submissionTrayAssignmentId === assignmentId && submissionTrayOpen) {
    useStore.setState({submissionTrayOpen: false, submissionTrayAssignmentId: undefined})
  } else {
    const {attempts, assignmentUrl} = getSubmissionCommentsTrayProps(assignmentId)
    useStore.setState({
      submissionCommentsTray: {attempts},
      submissionTrayOpen: true,
      submissionTrayAssignmentId: assignmentId,
      submissionTrayAssignmentUrl: assignmentUrl,
    })
  }
}

export const assignmentRow = (
  assignment,
  queryData,
  setShowTray,
  handleReadStateChange,
  handleRubricReadStateChange,
  setOpenAssignmentDetailIds,
  openAssignmentDetailIds,
  setSubmissionAssignmentId,
  submissionAssignmentId,
  setOpenRubricDetailIds,
  openRubricDetailIds,
  setActiveWhatIfScores,
  activeWhatIfScores
) => {
  const handleAssignmentDetailOpen = () => {
    if (!openAssignmentDetailIds.includes(assignment._id)) {
      setOpenAssignmentDetailIds([...openAssignmentDetailIds, assignment._id])
    } else {
      const arr = [...openAssignmentDetailIds]
      const index = arr.indexOf(assignment._id)
      if (index > -1) {
        arr.splice(index, 1)
        setOpenAssignmentDetailIds(arr)
      }
    }
  }

  const handleRubricDetailOpen = () => {
    if (assignment?.submissionsConnection?.nodes[0]?.hasUnreadRubricAssessment) {
      handleRubricReadStateChange(assignment?.submissionsConnection?.nodes[0]?._id)
    }
    if (!openRubricDetailIds.includes(assignment._id)) {
      setOpenRubricDetailIds([...openRubricDetailIds, assignment._id])
    } else {
      const arr = [...openRubricDetailIds]
      const index = arr.indexOf(assignment._id)
      if (index > -1) {
        arr.splice(index, 1)
        setOpenRubricDetailIds(arr)
      }
    }
  }

  const renderRubricButton = () => {
    return assignment?.submissionsConnection?.nodes[0]?.hasUnreadRubricAssessment ? (
      <Badge
        type="notification"
        formatOutput={() => (
          <ScreenReaderContent>{I18n.t('Unread rubric assessment')}</ScreenReaderContent>
        )}
      >
        <IconButton
          data-testid="rubric_detail_button_with_badge"
          margin="0 small"
          screenReaderLabel="Rubric Results"
          size="small"
          onClick={handleRubricDetailOpen}
          aria-expanded={openRubricDetailIds.includes(assignment._id)}
        >
          <IconRubricLine />
        </IconButton>
      </Badge>
    ) : (
      <IconButton
        data-testid="rubric_detail_button"
        margin="0 small"
        screenReaderLabel="Rubric Results"
        size="small"
        onClick={handleRubricDetailOpen}
        aria-expanded={openRubricDetailIds.includes(assignment._id)}
      >
        <IconRubricLine />
      </IconButton>
    )
  }

  return (
    <Table.Row
      data-testid="assignment-row"
      key={`assignment_${assignment._id}`}
      onMouseEnter={() => {
        if (assignment?.submissionsConnection?.nodes[0]?.readState !== 'read') {
          handleReadStateChange(assignment?.submissionsConnection?.nodes[0]?._id)
        }
      }}
    >
      <Table.Cell textAlign="start">
        <Flex direction="column">
          <Flex.Item>
            <a data-testid="assignment-link" href={assignment.htmlUrl}>
              {assignment.name}
            </a>
          </Flex.Item>
          <Flex.Item>
            <Text size="small">{assignment.assignmentGroup.name}</Text>
          </Flex.Item>
        </Flex>
      </Table.Cell>
      <Table.Cell textAlign="start">
        {DateHelper.formatDatetimeForDisplay(assignment.dueAt)}
      </Table.Cell>
      <Table.Cell textAlign="center">{getDisplayStatus(assignment)}</Table.Cell>
      <Table.Cell textAlign="center">
        {assignment?.submissionsConnection?.nodes[0]?.hideGradeFromStudent ? (
          <Tooltip renderTip={I18n.t('This assignment is muted')}>
            <IconMutedLine />
          </Tooltip>
        ) : (
          <Flex justifyItems="center">
            <Flex.Item
              onClick={() => {
                if (
                  !ENV.restrict_quantitative_data &&
                  !activeWhatIfScores.includes(assignment._id)
                ) {
                  setActiveWhatIfScores([...activeWhatIfScores, assignment._id])
                }
              }}
            >
              <View as="div" position="relative">
                {!ENV.restrict_quantitative_data &&
                activeWhatIfScores.includes(assignment._id) &&
                assignment?.gradingType !== 'not_graded' ? (
                  <WhatIfGrade
                    assignment={assignment}
                    setActiveWhatIfScores={setActiveWhatIfScores}
                    activeWhatIfScores={activeWhatIfScores}
                  />
                ) : (
                  <View
                    tabIndex="0"
                    role="button"
                    position="relative"
                    onKeyDown={event => {
                      if (event.key === 'Enter') {
                        if (
                          !ENV.restrict_quantitative_data &&
                          !activeWhatIfScores.includes(assignment._id)
                        ) {
                          setActiveWhatIfScores([...activeWhatIfScores, assignment._id])
                        }
                      }
                    }}
                  >
                    {ENV.restrict_quantitative_data ? (
                      getDisplayScore(assignment, queryData?.gradingStandard)
                    ) : (
                      <Tooltip renderTip={I18n.t('Click to test a different score')}>
                        {getDisplayScore(assignment, queryData?.gradingStandard)}
                      </Tooltip>
                    )}
                  </View>
                )}
              </View>
            </Flex.Item>
            {assignment?.submissionsConnection?.nodes.length > 0 &&
              assignment?.submissionsConnection?.nodes[0]?.readState !== 'read' && (
                <Flex.Item>
                  <div
                    style={{
                      float: 'right',
                      marginBottom: '1.5rem',
                    }}
                    data-testid="grade-is-unread"
                  >
                    <Badge
                      type="notification"
                      placement="start center"
                      standalone={true}
                      formatOutput={() => (
                        <ScreenReaderContent>
                          {I18n.t('Your grade has been updated')}
                        </ScreenReaderContent>
                      )}
                    />
                  </div>
                </Flex.Item>
              )}
          </Flex>
        )}
      </Table.Cell>
      <Table.Cell textAlign="end">
        <Flex justifyItems="end">
          <Flex.Item>
            {!ENV.restrict_quantitative_data &&
            assignment?.rubric &&
            assignment?.submissionsConnection?.nodes[0]?.rubricAssessmentsConnection?.nodes.length >
              0 ? (
              renderRubricButton()
            ) : (
              <View as="div" width="52px" />
            )}
          </Flex.Item>
          <Flex.Item>
            {!ENV.restrict_quantitative_data && assignment?.scoreStatistic ? (
              <IconButton
                margin="0 small"
                screenReaderLabel="Assignment Statistics"
                size="small"
                onClick={handleAssignmentDetailOpen}
                aria-expanded={openAssignmentDetailIds.includes(assignment._id)}
              >
                <IconAnalyticsLine />
              </IconButton>
            ) : (
              <View as="div" width="52px" />
            )}
          </Flex.Item>
          <Flex.Item>
            {submissionCommentsPresent(assignment) ? (
              <IconButton
                data-testid={`submission_comment_tray_${assignment?._id}`}
                margin="0 small"
                screenReaderLabel="Submission Comments"
                size="small"
                onClick={() => {
                  handleSubmissionsCommentTray(assignment?._id)
                  setSubmissionAssignmentId(assignment?._id)
                  setShowTray()
                }}
                aria-expanded={assignment?._id === submissionAssignmentId}
              >
                <IconCommentLine />
                <Text size="small">
                  {assignment?.submissionsConnection.nodes[0].commentsConnection.nodes.length}
                </Text>
              </IconButton>
            ) : (
              <View as="div" width="52px" />
            )}
          </Flex.Item>
        </Flex>
      </Table.Cell>
    </Table.Row>
  )
}

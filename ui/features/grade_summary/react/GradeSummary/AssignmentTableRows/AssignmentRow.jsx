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

import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
import {IconCommentLine, IconMutedLine, IconAnalyticsLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

import {getDisplayStatus, getDisplayScore, submissionCommentsPresent} from '../utils'

const I18n = useI18nScope('grade_summary')

export const assignmentRow = (
  assignment,
  queryData,
  setShowTray,
  setSelectedSubmission,
  handleReadStateChange,
  setOpenAssignmentDetailIds,
  openAssignmentDetailIds
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
            <Flex.Item>{getDisplayScore(assignment, queryData?.gradingStandard)}</Flex.Item>
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
            {!ENV.restrict_quantitative_data && assignment?.scoreStatistic && (
              <IconButton
                margin="0 small"
                screenReaderLabel="Assignment Details"
                size="small"
                onClick={handleAssignmentDetailOpen}
              >
                <IconAnalyticsLine />
              </IconButton>
            )}
          </Flex.Item>
          <Flex.Item>
            {submissionCommentsPresent(assignment) ? (
              <IconButton
                margin="0 small"
                screenReaderLabel="Submission Comments"
                size="small"
                onClick={() => {
                  setShowTray(true)
                  setSelectedSubmission(assignment?.submissionsConnection?.nodes[0])
                }}
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

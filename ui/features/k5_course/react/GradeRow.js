/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import I18n from 'i18n!k5_course_GradesPage'
import tz from '@canvas/timezone'
import PropTypes from 'prop-types'

import {Table} from '@instructure/ui-table'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {IconCheckDarkSolid, IconXSolid} from '@instructure/ui-icons'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Badge} from '@instructure/ui-badge'

import k5Theme from '@canvas/k5/react/k5-theme'

export const GradeRow = ({
  assignmentName,
  url,
  dueDate,
  assignmentGroupName,
  pointsPossible,
  gradingType,
  grade,
  submissionDate,
  unread,
  late,
  excused,
  missing
}) => {
  const renderStatus = () => {
    if (late) {
      return (
        <Text color="warning" size="small">
          {submissionDate
            ? I18n.t('Late %{date}', {
                date: tz.format(submissionDate, 'date.formats.full_with_weekday')
              })
            : I18n.t('Late')}
        </Text>
      )
    }
    if (missing) {
      return (
        <Text color="danger" size="small">
          {I18n.t('Missing')}
        </Text>
      )
    }
    if (submissionDate) {
      return (
        <Text color="success" size="small">
          {I18n.t('Submitted %{date}', {
            date: tz.format(submissionDate, 'date.formats.full_with_weekday')
          })}
        </Text>
      )
    }
    return null
  }

  const notGradedContent = (visualIndicator = I18n.t('—')) => (
    <AccessibleContent alt={I18n.t('Not graded')}>
      <Text>{visualIndicator}</Text>
    </AccessibleContent>
  )

  const renderScore = () => {
    if (excused) {
      return <Text>{I18n.t('Excused')}</Text>
    }

    const notGraded = grade == null
    const gradeString = notGraded ? '—' : grade

    switch (gradingType) {
      case 'points':
        return notGraded ? (
          notGradedContent(I18n.t('— pts'))
        ) : (
          <Text>{I18n.t('%{score} pts', {score: gradeString})}</Text>
        )
      case 'gpa_scale':
        return notGraded ? (
          notGradedContent(I18n.t('— GPA'))
        ) : (
          <Text>{I18n.t('%{gpa} GPA', {gpa: gradeString})}</Text>
        )
      case 'pass_fail':
        return notGraded ? (
          notGradedContent()
        ) : grade === 'complete' ? (
          <AccessibleContent alt={I18n.t('Complete')}>
            <IconCheckDarkSolid />
          </AccessibleContent>
        ) : (
          <AccessibleContent alt={I18n.t('Incomplete')}>
            <IconXSolid />
          </AccessibleContent>
        )
      case 'not_graded':
        return (
          <AccessibleContent alt={I18n.t('Ungraded assignment')}>
            <Text>--</Text>
          </AccessibleContent>
        )
      default:
        // Handles 'percent', 'letter_grade'
        return notGraded ? notGradedContent() : <Text>{grade}</Text>
    }
  }

  const renderTitleCell = () => (
    <Flex direction="column" margin="0 0 0 small">
      <Link
        href={url}
        isWithinText={false}
        theme={{
          color: k5Theme.variables.colors.textDarkest,
          hoverColor: k5Theme.variables.colors.textDarkest
        }}
      >
        {assignmentName}
      </Link>
      {renderStatus()}
    </Flex>
  )

  return (
    <Table.Row>
      <Table.Cell>
        {unread ? (
          <Badge
            type="notification"
            placement="start center"
            formatOutput={() => (
              <ScreenReaderContent>
                {I18n.t('New grade for %{assignmentName}', {assignmentName})}
              </ScreenReaderContent>
            )}
            theme={{
              sizeNotification: '0.45rem'
            }}
          >
            {renderTitleCell()}
          </Badge>
        ) : (
          renderTitleCell()
        )}
      </Table.Cell>
      <Table.Cell>
        {dueDate && <Text>{tz.format(dueDate, 'date.formats.full_with_weekday')}</Text>}
      </Table.Cell>
      <Table.Cell>
        <Text>{assignmentGroupName}</Text>
      </Table.Cell>
      <Table.Cell>
        <Flex direction="column">
          {renderScore()}
          {pointsPossible && (
            <Text size="x-small">{I18n.t('Out of %{pointsPossible} pts', {pointsPossible})}</Text>
          )}
        </Flex>
      </Table.Cell>
    </Table.Row>
  )
}

GradeRow.propTypes = {
  assignmentName: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
  dueDate: PropTypes.string,
  assignmentGroupName: PropTypes.string.isRequired,
  pointsPossible: PropTypes.number,
  gradingType: PropTypes.oneOf([
    'pass_fail',
    'percent',
    'letter_grade',
    'gpa_scale',
    'points',
    'not_graded'
  ]).isRequired,
  grade: PropTypes.string,
  submissionDate: PropTypes.string,
  unread: PropTypes.bool.isRequired,
  late: PropTypes.bool,
  excused: PropTypes.bool,
  missing: PropTypes.bool
}

GradeRow.displayName = 'Row'

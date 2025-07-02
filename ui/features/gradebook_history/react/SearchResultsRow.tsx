/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {datetimeString} from '@canvas/datetime/date-functions'
import environment from './environment'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import NumberHelper from '@canvas/i18n/numberHelper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconOffLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('gradebook_history')

interface Assignment {
  anonymousGrading: boolean
  muted: boolean
  name: string
  subAssignmentTag?: string
}

interface SearchResultsRowItem {
  assignment?: Assignment
  courseOverrideGrade: boolean
  date: string
  displayAsPoints: boolean
  gradedAnonymously: boolean
  grader: string
  gradeAfter: string
  gradeBefore: string
  gradeCurrent: string
  pointsPossibleAfter: string
  pointsPossibleBefore: string
  pointsPossibleCurrent: string
  student: string
}

interface SearchResultsRowProps {
  item: SearchResultsRowItem
}

// Unclear on why that tab-index is there but not going to mess with it right now
/* eslint-disable jsx-a11y/no-noninteractive-tabindex */
function anonymouslyGraded(gradedAnonymously: boolean) {
  return gradedAnonymously ? (
    <div>
      <Tooltip renderTip={I18n.t('Anonymously graded')} on={['focus', 'hover']}>
        <span role="presentation" tabIndex={0}>
          <IconOffLine />
          <ScreenReaderContent>{I18n.t('Anonymously graded')}</ScreenReaderContent>
        </span>
      </Tooltip>
    </div>
  ) : (
    <ScreenReaderContent>{I18n.t('Not anonymously graded')}</ScreenReaderContent>
  )
}
/* eslint-enable jsx-a11y/no-noninteractive-tabindex */

function displayGrade(grade: string, possible: string, displayAsPoints: boolean) {
  // show the points possible if the assignment is set to display grades as
  // "points" and the grade can be parsed as a number
  if (displayAsPoints && NumberHelper.validate(grade)) {
    return `${GradeFormatHelper.formatGrade(grade, {
      defaultValue: '–',
    })}/${GradeFormatHelper.formatGrade(possible)}`
  }

  return GradeFormatHelper.formatGrade(grade, {defaultValue: '–'})
}

function displayStudentName(studentName: string, assignment?: Assignment) {
  if (assignment != null && assignment.anonymousGrading && assignment.muted) {
    return I18n.t('Not available; assignment is anonymous')
  }

  if (!studentName) {
    return I18n.t('Not available')
  }

  return studentName
}

function getCheckpointedName(name: string, subAssignmentTag: string) {
  return subAssignmentTag === 'reply_to_topic'
    ? I18n.t(`%{name} (Reply to Topic)`, {name})
    : I18n.t(`%{name} (Required Replies)`, {name})
}

function displayAssignmentName(assignment?: Assignment, courseOverrideGrade?: boolean) {
  if (courseOverrideGrade) {
    return <Text fontStyle="italic">{I18n.t('Final Grade Override')}</Text>
  }

  const nameToDisplay = assignment?.subAssignmentTag
    ? getCheckpointedName(assignment.name, assignment.subAssignmentTag)
    : assignment?.name

  return <Text>{assignment?.name ? nameToDisplay : I18n.t('Not available')}</Text>
}

const SearchResultsRow: React.FC<SearchResultsRowProps> = props => {
  const {
    assignment,
    courseOverrideGrade,
    date,
    displayAsPoints,
    gradedAnonymously,
    grader,
    gradeAfter,
    gradeBefore,
    gradeCurrent,
    pointsPossibleAfter,
    pointsPossibleBefore,
    pointsPossibleCurrent,
    student,
  } = props.item

  return (
    <Table.Row>
      <Table.Cell>
        {datetimeString(new Date(date), {format: 'medium', timezone: environment.timezone()})}
      </Table.Cell>
      <Table.Cell>{anonymouslyGraded(gradedAnonymously)}</Table.Cell>
      <Table.Cell>{displayStudentName(student, assignment)}</Table.Cell>
      <Table.Cell>{grader || I18n.t('Not available')}</Table.Cell>
      <Table.Cell>{displayAssignmentName(assignment, courseOverrideGrade)}</Table.Cell>
      <Table.Cell>{displayGrade(gradeBefore, pointsPossibleBefore, displayAsPoints)}</Table.Cell>
      <Table.Cell>{displayGrade(gradeAfter, pointsPossibleAfter, displayAsPoints)}</Table.Cell>
      <Table.Cell>{displayGrade(gradeCurrent, pointsPossibleCurrent, displayAsPoints)}</Table.Cell>
    </Table.Row>
  )
}

SearchResultsRow.displayName = 'Row'

export default SearchResultsRow

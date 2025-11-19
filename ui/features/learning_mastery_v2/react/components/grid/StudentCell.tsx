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
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Outcome, Student, StudentRollupData} from '../../types/rollup'
import {SecondaryInfoDisplay, NameDisplayFormat} from '../../utils/constants'
import {Text} from '@instructure/ui-text'
import {StudentCellPopover} from './StudentCellPopover'

export interface StudentCellProps {
  courseId: string
  student: Student
  secondaryInfoDisplay?: SecondaryInfoDisplay
  showStudentAvatar?: boolean
  nameDisplayFormat?: NameDisplayFormat
  outcomes?: Outcome[]
  rollups?: StudentRollupData[]
}

const getSecondaryInfo = (student: Student, secondaryInfoDisplay?: SecondaryInfoDisplay) => {
  if (!secondaryInfoDisplay) return null

  switch (secondaryInfoDisplay) {
    case SecondaryInfoDisplay.SIS_ID:
      return student.sis_id || ''
    case SecondaryInfoDisplay.INTEGRATION_ID:
      return student.integration_id || ''
    case SecondaryInfoDisplay.LOGIN_ID:
      return student.login_id || ''
    default:
      return null
  }
}

export const StudentCell: React.FC<StudentCellProps> = ({
  courseId,
  student,
  secondaryInfoDisplay,
  showStudentAvatar = true,
  nameDisplayFormat,
  outcomes,
  rollups,
}) => {
  const studentGradesUrl = `/courses/${courseId}/grades/${student.id}#tab-outcomes`
  const shouldShowStudentStatus = student.status === 'inactive' || student.status === 'concluded'
  const displayNameWidth = shouldShowStudentStatus ? '50%' : showStudentAvatar ? '75%' : '100%'
  const secondaryInfo = getSecondaryInfo(student, secondaryInfoDisplay)
  const studentName =
    nameDisplayFormat === NameDisplayFormat.LAST_FIRST
      ? student.sortable_name
      : student.display_name

  return (
    <Flex height="100%" alignItems="center" justifyItems="start" data-testid="student-cell">
      {showStudentAvatar && (
        <Flex.Item as="div" size="25%" textAlign="center">
          <Avatar
            alt={studentName}
            as="div"
            size="x-small"
            name={studentName}
            src={student.avatar_url}
            data-testid="student-avatar"
          />
        </Flex.Item>
      )}
      <Flex.Item as="div" size={displayNameWidth} padding="none x-small">
        <Flex direction="column">
          <StudentCellPopover
            key={student.id}
            student={student}
            studentName={studentName}
            studentGradesUrl={studentGradesUrl}
            courseId={courseId}
            outcomes={outcomes}
            rollups={rollups}
          />
          {secondaryInfo !== null && (
            <Text size="legend" color="secondary" data-testid="student-secondary-info">
              {secondaryInfo}
            </Text>
          )}
        </Flex>
      </Flex.Item>
      {shouldShowStudentStatus && (
        <Flex.Item size="25%" data-testid="student-status">
          <span className="label">{student.status}</span>
        </Flex.Item>
      )}
    </Flex>
  )
}

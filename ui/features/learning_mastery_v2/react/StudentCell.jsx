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
import PropTypes from 'prop-types'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {studentShape} from './shapes'

const StudentCell = ({courseId, student}) => {
  const student_grades_url = `/courses/${courseId}/grades/${student.id}#tab-outcomes`

  const shouldShowStudentStatus = student.status === 'inactive' || student.status === 'concluded'
  const displayNameWidth = shouldShowStudentStatus ? '50%' : '75%'

  return (
    <>
      <Flex maxWidth="100%" height="100%" alignItems="center" justifyItems="start">
        <Flex.Item as="div" padding="0 0 0 small" maxWidth="25%">
          <Avatar
            alt={student.display_name}
            as="div"
            size="x-small"
            name={student.display_name}
            src={student.avatar_url}
            data-testid="student-avatar"
          />
        </Flex.Item>
        <Flex.Item as="div" padding="0 xx-small 0 small" maxWidth={displayNameWidth}>
          <Link isWithinText={false} href={student_grades_url} data-testid="student-cell-link">
            <TruncateText>{student.display_name}</TruncateText>
          </Link>
        </Flex.Item>
        {shouldShowStudentStatus && (
          <Flex.Item maxWidth="25%" data-testid="student-status">
            <span className="label">{student.status}</span>
          </Flex.Item>
        )}
      </Flex>
    </>
  )
}

StudentCell.propTypes = {
  courseId: PropTypes.string.isRequired,
  student: PropTypes.shape(studentShape).isRequired,
}

export default StudentCell

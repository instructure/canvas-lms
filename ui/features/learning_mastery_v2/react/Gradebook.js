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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import StudentCell from './StudentCell'
import OutcomeHeader from './OutcomeHeader'
import StudentHeader from './StudentHeader'
import {studentShape, outcomeShape} from './shapes'

const Gradebook = ({courseId, students, outcomes}) => (
  <View as="div" padding="medium 0 0 0">
    <Flex>
      <Flex.Item size="185px" overflowX="hidden" borderWidth="large 0 medium 0">
        <StudentHeader />
      </Flex.Item>
      <Flex.Item size="16px" />
      {outcomes.map(({id, title}) => (
        <React.Fragment key={id}>
          <Flex.Item size="180px" overflowX="hidden" borderWidth="large 0 medium 0">
            <OutcomeHeader title={title} />
          </Flex.Item>
          <Flex.Item size="5px" />
        </React.Fragment>
      ))}
    </Flex>
    {students.map(student => (
      <View
        key={student.id}
        as="div"
        background="primary"
        height="50px"
        borderWidth="0 small small 0"
        maxWidth="185px"
        overflowX="auto"
      >
        <StudentCell courseId={courseId} student={student} />
      </View>
    ))}
  </View>
)

Gradebook.propTypes = {
  courseId: PropTypes.string.isRequired,
  students: PropTypes.arrayOf(PropTypes.shape(studentShape)).isRequired,
  outcomes: PropTypes.arrayOf(PropTypes.shape(outcomeShape)).isRequired
}
export default Gradebook

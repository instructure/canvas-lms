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
import React, {useRef, useEffect} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import StudentCell from './StudentCell'
import OutcomeHeader from './OutcomeHeader'
import StudentHeader from './StudentHeader'
import ScoresGrid from './ScoresGrid'
import {studentShape, outcomeShape, studentRollupsShape} from './shapes'
import {
  COLUMN_WIDTH,
  STUDENT_COLUMN_WIDTH,
  STUDENT_COLUMN_RIGHT_PADDING,
  COLUMN_PADDING,
  CELL_HEIGHT,
} from './constants'

const Gradebook = ({
  courseId,
  students,
  outcomes,
  rollups,
  visibleRatings,
  gradebookFilters,
  gradebookFilterHandler,
}) => {
  const headerRow = useRef(null)
  const gridRef = useRef(null)

  useEffect(() => {
    const handleGridScroll = e => (headerRow.current.scrollLeft = e.target.scrollLeft)
    gridRef.current.addEventListener('scroll', handleGridScroll)
    return function cleanup() {
      gridRef.current.removeEventListener('scroll', handleGridScroll)
    }
  }, [])

  return (
    <>
      <Flex padding="medium 0 0 0">
        <Flex.Item borderWidth="large 0 medium 0">
          <StudentHeader
            gradebookFilters={gradebookFilters}
            gradebookFilterHandler={gradebookFilterHandler}
          />
        </Flex.Item>
        <Flex.Item size={`${STUDENT_COLUMN_RIGHT_PADDING}px`} />
        <View
          as="div"
          display="flex"
          id="outcomes-header"
          overflowX="hidden"
          elementRef={el => (headerRow.current = el)}
        >
          {outcomes.map((outcome, index) => (
            // eslint-disable-next-line react/no-array-index-key
            <Flex.Item size={`${COLUMN_WIDTH + COLUMN_PADDING}px`} key={`${outcome.id}.${index}`}>
              <OutcomeHeader outcome={outcome} />
            </Flex.Item>
          ))}
        </View>
      </Flex>
      <View display="flex">
        <View as="div" minWidth={STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING}>
          {students.map(student => (
            <View
              key={student.id}
              as="div"
              overflowX="auto"
              background="primary"
              borderWidth="0 0 small 0"
              height={CELL_HEIGHT}
              width={STUDENT_COLUMN_WIDTH}
            >
              <StudentCell courseId={courseId} student={student} />
            </View>
          ))}
        </View>
        <View
          as="div"
          overflowX="auto"
          overflowY="auto"
          elementRef={el => (gridRef.current = el)}
          width={outcomes.length * COLUMN_WIDTH}
        >
          <ScoresGrid
            students={students}
            outcomes={outcomes}
            rollups={rollups}
            visibleRatings={visibleRatings}
          />
        </View>
      </View>
    </>
  )
}

Gradebook.propTypes = {
  courseId: PropTypes.string.isRequired,
  students: PropTypes.arrayOf(PropTypes.shape(studentShape)).isRequired,
  outcomes: PropTypes.arrayOf(PropTypes.shape(outcomeShape)).isRequired,
  rollups: PropTypes.arrayOf(PropTypes.shape(studentRollupsShape)).isRequired,
  visibleRatings: PropTypes.arrayOf(PropTypes.bool).isRequired,
  gradebookFilters: PropTypes.arrayOf(PropTypes.string).isRequired,
  gradebookFilterHandler: PropTypes.func.isRequired,
}

export default Gradebook

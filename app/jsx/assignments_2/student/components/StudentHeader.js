/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'

import AssignmentGroupModuleNav from './AssignmentGroupModuleNav'
import StudentDateTitle from './StudentDateTitle'
import PointsDisplay from './PointsDisplay'
import StepContainer from './StepContainer'

function StudentHeader() {
  return (
    <div data-test-id="assignments-2-student-header">
      <AssignmentGroupModuleNav
        module={{name: 'Egypt Economy Research Module: Week 1', link: 'www.google.com'}}
        assignmentGroup={{name: 'Research Assignments', link: 'www.yahoo.com'}}
      />
      <Flex margin="0 0 xx-large 0">
        <FlexItem grow>
          <StudentDateTitle
            title="Egypt Economy Research"
            dueDate={new Date('12/28/2018 23:59:00')}
          />
        </FlexItem>
        <FlexItem grow>
          <PointsDisplay receivedPoints={null} possiblePoints={32} />
        </FlexItem>
      </Flex>
      <StepContainer />
    </div>
  )
}

export default React.memo(StudentHeader)

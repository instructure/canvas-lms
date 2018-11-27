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

import {AssignmentShape} from '../../shared/shapes'

StudentHeader.propTypes = {
  assignment: AssignmentShape
}

function StudentHeader(props) {
  let assignmentGroup = null
  if (props.assignment.assignmentGroup.name) {
    assignmentGroup = {
      name: props.assignment.assignmentGroup.name,
      link: `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
        ENV.context_asset_string.split('_')[1]
      }/assignments`
    }
  }
  return (
    <div data-test-id="assignments-2-student-header">
      <AssignmentGroupModuleNav
        module={{
          name: 'Egypt Economy Research Module: Week 1',
          link: `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
            ENV.context_asset_string.split('_')[1]
          }/modules`
        }}
        assignmentGroup={assignmentGroup}
      />
      <Flex margin="0 0 xx-large 0">
        <FlexItem grow>
          <StudentDateTitle assignment={props.assignment} />
        </FlexItem>
        <FlexItem grow>
          <PointsDisplay receivedPoints={null} possiblePoints={props.assignment.pointsPossible} />
        </FlexItem>
      </Flex>
      <StepContainer assignment={props.assignment} />
    </div>
  )
}

export default React.memo(StudentHeader)

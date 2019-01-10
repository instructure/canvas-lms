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
import Heading from '@instructure/ui-elements/lib/components/Heading'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import AssignmentGroupModuleNav from './AssignmentGroupModuleNav'
import DateTitle from './DateTitle'
import PointsDisplay from './PointsDisplay'
import StepContainer from './StepContainer'

import {StudentAssignmentShape} from '../assignmentData'

Header.propTypes = {
  assignment: StudentAssignmentShape
}

function Header(props) {
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
      <Heading level="h1">
        {/* We hide this because in the designs, what visually looks like should
            be the h1 appears after the group/module links, but we need the
            h1 to actually come before them for a11y */}
        <ScreenReaderContent> {props.assignment.name} </ScreenReaderContent>
      </Heading>

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
          <DateTitle assignment={props.assignment} />
        </FlexItem>
        <FlexItem grow>
          <PointsDisplay
            displayAs={props.assignment.gradingType}
            receivedGrade={
              props.assignment.submissionsConnection &&
              props.assignment.submissionsConnection.nodes[0] &&
              props.assignment.submissionsConnection.nodes[0].grade
            }
            possiblePoints={props.assignment.pointsPossible}
          />
        </FlexItem>
      </Flex>
      <StepContainer assignment={props.assignment} />
    </div>
  )
}

export default React.memo(Header)

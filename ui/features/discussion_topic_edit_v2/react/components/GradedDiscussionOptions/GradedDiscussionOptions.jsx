/* eslint-disable @typescript-eslint/no-unused-vars */

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
import PropTypes from 'prop-types'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {AssignmentGroupSelect} from './AssignmentGroupSelect'
import {PointsPossible} from './PointsPossible'
import {DisplayGradeAs} from './DisplayGradeAs'

// TODO: remove eslint-disable once this component is implemented
// at the top of the file
export const GradedDiscussionOptions = ({
  assignmentGroups,
  pointsPossible,
  setPointsPossible,
  displayGradeAs,
  setDisplayGradeAs,
  assignmentGroup,
  setAssignmentGroup,
  peerReviewAssignment,
  setPeerReviewAssignment,
  assignTo,
  setAssignTo,
  dueDate,
  setDueDate,
}) => {
  return (
    <View as="div">
      <View as="div" margin="medium 0">
        <PointsPossible pointsPossible={pointsPossible} setPointsPossible={setPointsPossible} />
      </View>
      <View as="div" margin="medium 0">
        <DisplayGradeAs displayGradeAs={displayGradeAs} setDisplayGradeAs={setDisplayGradeAs} />
      </View>
      <View as="div" margin="medium 0">
        <AssignmentGroupSelect
          assignmentGroup={assignmentGroup}
          setAssignmentGroup={setAssignmentGroup}
          availableAssignmentGroups={assignmentGroups}
        />
      </View>
      <View as="div" margin="medium 0">
        <Text>Peer Review</Text>
      </View>
      <View as="div" margin="medium 0">
        <Text>Assignment Settings</Text>
      </View>
    </View>
  )
}

GradedDiscussionOptions.propTypes = {
  assignmentGroups: PropTypes.array,
  pointsPossible: PropTypes.number,
  setPointsPossible: PropTypes.func,
  displayGradeAs: PropTypes.string,
  setDisplayGradeAs: PropTypes.func,
  assignmentGroup: PropTypes.string,
  setAssignmentGroup: PropTypes.func,
  peerReviewAssignment: PropTypes.string,
  setPeerReviewAssignment: PropTypes.func,
  assignTo: PropTypes.string,
  setAssignTo: PropTypes.func,
  dueDate: PropTypes.string,
  setDueDate: PropTypes.func,
}

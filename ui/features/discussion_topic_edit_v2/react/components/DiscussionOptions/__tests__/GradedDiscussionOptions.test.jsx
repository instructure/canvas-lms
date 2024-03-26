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

import {render} from '@testing-library/react'
import React from 'react'

import {GradedDiscussionOptions} from '../GradedDiscussionOptions'

const defaultProps = {
  assignmentGroups: [],
  pointsPossible: 10,
  setPointsPossible: () => {},
  displayGradeAs: 'points',
  setDisplayGradeAs: () => {},
  assignmentGroup: '',
  setAssignmentGroup: () => {},
  peerReviewAssignment: '',
  setPeerReviewAssignment: () => {},
  peerReviewsPerStudent: 0,
  setPeerReviewsPerStudent: () => {},
  peerReviewDueDate: '',
  setPeerReviewDueDate: () => {},
  assignedInfoList: [],
  setAssignedInfoList: () => {},
  isCheckpoints: false,
}

const renderGradedDiscussionOptions = (props = {}) => {
  return render(<GradedDiscussionOptions {...defaultProps} {...props} />)
}
describe('GradedDiscussionOptions', () => {
  it('renders', () => {
    const {getByText} = renderGradedDiscussionOptions()
    expect(getByText('Points Possible')).toBeInTheDocument()
    expect(getByText('Display Grade As')).toBeInTheDocument()
    expect(getByText('Assignment Group')).toBeInTheDocument()
    expect(getByText('Peer Reviews')).toBeInTheDocument()
    expect(getByText('Assignment Settings')).toBeInTheDocument()
  })

  it('renders with null points possible value', () => {
    const {getByText} = renderGradedDiscussionOptions({pointsPossible: null})
    expect(getByText('Points Possible')).toBeInTheDocument()
    expect(getByText('Display Grade As')).toBeInTheDocument()
    expect(getByText('Assignment Group')).toBeInTheDocument()
    expect(getByText('Peer Reviews')).toBeInTheDocument()
    expect(getByText('Assignment Settings')).toBeInTheDocument()
  })

  describe('Checkpoints', () => {
    it('renders the section Checkpoint Settings when the checkpoints checkbox is selected', () => {
      const {getByText} = renderGradedDiscussionOptions({isCheckpoints: true})
      expect(getByText('Checkpoint Settings')).toBeInTheDocument()
    })
  })
})

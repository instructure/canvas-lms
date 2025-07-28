/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {
  Assignment,
  SubAssignmentSubmission,
  SubmissionGradeParams,
  SubmissionStatusParams,
} from '../SpeedGraderCheckpointsContainer'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'
import {fireEvent, render, screen} from '@testing-library/react'
import React from 'react'
import {SpeedGraderCheckpoint} from '../SpeedGraderCheckpoint'

const generateAssignment = (
  id: string,
  points_possible = 3,
  grading_type = 'points',
): Assignment => ({
  id,
  course_id: '1',
  points_possible,
  grading_type,
  checkpoints: [
    {
      tag: 'reply_to_topic',
      points_possible,
    },
    {
      tag: 'reply_to_entry',
      points_possible: 9,
    },
  ],
})

const generateSubAssignmentSubmission = (
  sub_assignment_tag: 'reply_to_topic' | 'reply_to_entry' | null,
  user_id: string,
  grade_matches_current_submission: boolean = true,
  missing: boolean = false,
  late: boolean = false,
  secondsLate: number = 0,
): SubAssignmentSubmission => ({
  sub_assignment_tag,
  score: 0,
  excused: false,
  late_policy_status: 'none',
  seconds_late: secondsLate,
  custom_grade_status_id: null,
  grade: '0',
  user_id,
  grade_matches_current_submission,
  entered_grade: '1',
  missing,
  late,
})

const getCustomGradeStatus = (id: string, name: string) => ({
  id,
  name,
  color: 'blue',
})

const getDefaultProps = (
  subAssignmentTag: 'reply_to_topic' | 'reply_to_entry' = 'reply_to_topic',
  pointsPossible: number = 3,
  gradingType: string = 'points',
  grade_matches_current_submission: boolean = true,
  missing: boolean = false,
  late: boolean = false,
  secondsLate: number = 0,
  lateSubmissionInterval: string = 'day',
) => ({
  assignment: generateAssignment('1', pointsPossible, gradingType),
  subAssignmentSubmission: generateSubAssignmentSubmission(
    subAssignmentTag,
    '1',
    grade_matches_current_submission,
    missing,
    late,
    secondsLate,
  ),
  customGradeStatusesEnabled: true,
  customGradeStatuses: [
    getCustomGradeStatus('1', 'Custom Grade Status 1'),
    getCustomGradeStatus('2', 'Custom Grade Status 2'),
  ],
  lateSubmissionInterval: lateSubmissionInterval,
  updateSubmissionGrade: jest.fn(),
  updateSubmissionStatus: jest.fn(),
  setLastSubmission: jest.fn(),
})

const setup = (props: {
  assignment: Assignment
  subAssignmentSubmission: SubAssignmentSubmission
  customGradeStatusesEnabled: boolean
  customGradeStatuses?: GradeStatusUnderscore[]
  lateSubmissionInterval: string
  updateSubmissionGrade: (params: SubmissionGradeParams) => void
  updateSubmissionStatus: (params: SubmissionStatusParams) => void
  setLastSubmission: (params: SubAssignmentSubmission) => void
}) => {
  return render(<SpeedGraderCheckpoint {...props} />)
}

describe('SpeedGraderCheckpoint', () => {
  it('renders', () => {
    const props = getDefaultProps()
    const container = setup(props)

    expect(container).toBeDefined()
  })

  it('renders the correct label for reply_to_topic', () => {
    const props = getDefaultProps('reply_to_topic')
    const {getByText} = setup(props)

    expect(getByText('Reply to Topic')).toBeDefined()
  })

  it('renders the correct label for reply_to_entry', () => {
    const props = getDefaultProps('reply_to_entry')
    const {getByText} = setup(props)

    expect(getByText('Required Replies')).toBeDefined()
  })

  it('renders the correct grading label if grading_type is points', () => {
    const props = getDefaultProps()
    const {getByText} = setup(props)

    expect(getByText('Grade out of 3')).toBeDefined()
  })

  it('renders the correct grading label if grading_type is gpa_scale', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'gpa_scale')
    const {getByText} = setup(props)

    expect(getByText('Grade')).toBeDefined()
  })

  it('renders the correct grading label if grading_type is pass_fail', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'pass_fail')
    const {getByText} = setup(props)

    expect(getByText('Grade (0 / 3)')).toBeDefined()
  })

  it('renders the correct grading label if grading_type is percent', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'percent')
    const {getByText} = setup(props)

    expect(getByText('Grade (0 / 3)')).toBeDefined()
  })

  it('renders the correct grading label if grading_type is letter_grade', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'letter_grade')
    const {getByText} = setup(props)

    expect(getByText('Grade (0 / 3)')).toBeDefined()
  })

  it('render statuses label, statuses and custom statuses options correctly', () => {
    const props = getDefaultProps()
    const {getByText, getByTestId} = setup(props)

    expect(getByText('Status')).toBeDefined()

    const statusSelector = getByTestId('reply_to_topic-checkpoint-status-select')
    fireEvent.click(statusSelector)

    expect(getByText('None')).toBeDefined()
    expect(getByText('Late')).toBeDefined()
    expect(getByText('Missing')).toBeDefined()
    expect(getByText('Excused')).toBeDefined()
    expect(getByText('Extended')).toBeDefined()
    expect(getByText('Custom Grade Status 1')).toBeDefined()
    expect(getByText('Custom Grade Status 2')).toBeDefined()
  })

  it('renders time late input correctly', () => {
    const props = getDefaultProps()
    const {getByText, getByTestId} = setup(props)

    const statusSelector = getByTestId('reply_to_topic-checkpoint-status-select')
    fireEvent.click(statusSelector)
    fireEvent.click(getByText('Late'))

    expect(getByText('Days Late')).toBeDefined()

    const timeLateInput = getByTestId('reply_to_topic-checkpoint-time-late-input')

    expect(timeLateInput).toBeDefined()
  })

  it('calls updateSubmissionGrade when the grade input is changed', () => {
    const props = getDefaultProps()
    const {getByTestId} = setup(props)

    const gradeInput = getByTestId('grade-input')
    fireEvent.change(gradeInput, {target: {value: '3'}})
    fireEvent.blur(gradeInput)

    expect(props.updateSubmissionGrade).toHaveBeenCalledWith({
      subAssignmentTag: 'reply_to_topic',
      courseId: '1',
      assignmentId: '1',
      studentId: '1',
      grade: '3',
    })
  })

  it('calls setLastSubmission when the grade input is changed', () => {
    const props = getDefaultProps()
    const {getByTestId} = setup(props)

    const gradeInput = getByTestId('grade-input')
    fireEvent.change(gradeInput, {target: {value: '3'}})
    fireEvent.blur(gradeInput)

    expect(props.setLastSubmission).toHaveBeenCalledWith({
      sub_assignment_tag: 'reply_to_topic',
      grade: '3',
    })
  })

  it('calls updateSubmissionStatus when the status is changed or days late changed', () => {
    const props = getDefaultProps()
    const {getByTestId, getByText} = setup(props)

    const statusSelector = getByTestId('reply_to_topic-checkpoint-status-select')
    fireEvent.click(statusSelector)
    fireEvent.click(getByText('Late'))

    expect(props.updateSubmissionStatus).toHaveBeenCalledWith({
      subAssignmentTag: 'reply_to_topic',
      courseId: '1',
      assignmentId: '1',
      studentId: '1',
      latePolicyStatus: 'late',
    })

    const timeLateInput = getByTestId('reply_to_topic-checkpoint-time-late-input')
    fireEvent.change(timeLateInput, {target: {value: '3'}})
    fireEvent.blur(timeLateInput)

    expect(props.updateSubmissionStatus).toHaveBeenCalledWith({
      subAssignmentTag: 'reply_to_topic',
      courseId: '1',
      assignmentId: '1',
      studentId: '1',
      secondsLate: 3 * 24 * 3600,
    })
  })

  it('renders the correct grading options if grading_type is pass_fail', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'pass_fail')
    const {getByTestId, getByText} = setup(props)

    const passFailSelect = getByTestId('pass-fail-select')
    expect(passFailSelect).toBeDefined()

    fireEvent.click(passFailSelect)
    expect(getByText('---')).toBeDefined()
    expect(getByText('Complete')).toBeDefined()
    expect(getByText('Incomplete')).toBeDefined()
  })

  it('calls updateSubmissionGrade when the grade input is changed and the grading type is pass fail', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'pass_fail')
    const {getByText, getByTestId} = setup(props)

    const passFailSelect = getByTestId('pass-fail-select')
    fireEvent.click(passFailSelect)
    fireEvent.click(getByText('Complete'))

    expect(props.updateSubmissionGrade).toHaveBeenCalledWith({
      subAssignmentTag: 'reply_to_topic',
      courseId: '1',
      assignmentId: '1',
      studentId: '1',
      grade: 'complete',
    })
  })

  it('renders the None status if there is no status', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'points')
    const {queryByTestId, getByTestId} = setup(props)

    const statusSelector = getByTestId('reply_to_topic-checkpoint-status-select')
    expect(statusSelector).toHaveValue('None')
    expect(queryByTestId('reply_to_topic-checkpoint-time-late-input')).toBeFalsy()
  })

  it('renders the Missing status if the submission is missing', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'points', true, true, false)
    const {getByTestId} = setup(props)

    const statusSelector = getByTestId('reply_to_topic-checkpoint-status-select')
    expect(statusSelector).toHaveValue('Missing')
  })

  it('renders the Late status if the submission is late', () => {
    const props = getDefaultProps('reply_to_topic', 3, 'points', true, false, true)
    const {queryByTestId, getByTestId} = setup(props)

    const statusSelector = getByTestId('reply_to_topic-checkpoint-status-select')
    expect(statusSelector).toHaveValue('Late')
    expect(queryByTestId('reply_to_topic-checkpoint-time-late-input')).toBeTruthy()
  })

  it('renders the Late days rounded up if the submission is late', () => {
    const SECONDS_IN_A_DAY = 24 * 3600
    const props = getDefaultProps('reply_to_topic', 3, 'points', true, false, true, SECONDS_IN_A_DAY * 6 + 1)
    setup(props)
    const relyToTopicLateInput = screen.getByLabelText('Days Late')
    expect(relyToTopicLateInput).toHaveValue("7")
  })

  it('renders the Late hours rounded up if the submission is late', () => {
    const SECONDS_IN_AN_HOUR = 3600
    const props = getDefaultProps('reply_to_topic', 3, 'points', true, false, true, SECONDS_IN_AN_HOUR * 6 + 1, 'hour')
    setup(props)
    const relyToTopicLateInput = screen.getByLabelText('Hours Late')
    expect(relyToTopicLateInput).toHaveValue("7")
  })

  describe('UseSameGrade', () => {
    it('renders', () => {
      const props = getDefaultProps('reply_to_topic', 3, 'pass_fail', false)
      const {queryByTestId} = setup(props)

      expect(queryByTestId('use-same-grade-link')).toBeDefined()
    })

    it('does not render', () => {
      const props = getDefaultProps('reply_to_topic', 3, 'pass_fail', true)
      const {queryByTestId} = setup(props)

      expect(queryByTestId('use-same-grade-link')).toBeNull()
    })

    it('calls updateSubmissionGrade when clicking on the link', () => {
      const props = getDefaultProps('reply_to_topic', 3, 'pass_fail', false)
      const {getByTestId} = setup(props)

      fireEvent.click(getByTestId('use-same-grade-link'))

      expect(props.updateSubmissionGrade).toHaveBeenCalledWith({
        subAssignmentTag: 'reply_to_topic',
        courseId: '1',
        assignmentId: '1',
        studentId: '1',
        grade: '1',
      })
    })
  })
})

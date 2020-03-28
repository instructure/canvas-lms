/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import {mockQuery} from '../../mocks'
import React from 'react'
import RubricTab from '../RubricTab'
import {RUBRIC_QUERY} from '../../graphqlData/Queries'

function gradedOverrides() {
  return {
    Submission: {
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 1,
            score: 5,
            assessor: {name: 'assessor1', enrollments: []}
          },
          {
            _id: 2,
            score: 10,
            assessor: null
          },
          {
            _id: 3,
            score: 8,
            assessor: {name: 'assessor2', enrollments: [{type: 'TaEnrollment'}]}
          }
        ]
      }
    },
    Course: {
      account: {
        proficiencyRatingsConnection: {
          nodes: [{}]
        }
      }
    }
  }
}

function ungradedOverrides() {
  return {
    Submission: {rubricAssessmentsConnection: null},
    Course: {
      account: {
        proficiencyRatingsConnection: null
      }
    }
  }
}

async function makeProps(opts = {}) {
  const variables = {
    courseID: '1',
    assignmentLid: '1',
    submissionID: '1',
    submissionAttempt: 0
  }

  const overrides = opts.graded ? gradedOverrides() : ungradedOverrides()
  const allOverrides = [
    {
      Node: {__typename: 'Assignment'},
      Assignment: {rubric: {}},
      Rubric: {
        criteria: [{}]
      },
      ...overrides
    }
  ]

  const result = await mockQuery(RUBRIC_QUERY, allOverrides, variables)
  return {
    assessments: result.data.submission.rubricAssessmentsConnection?.nodes,
    proficiencyRatings: result.data.course.account.proficiencyRatingsConnection?.nodes,
    rubric: result.data.assignment.rubric
  }
}

describe('RubricTab', () => {
  describe('ungraded rubric', () => {
    it('contains the rubric criteria heading', async () => {
      const props = await makeProps({graded: false})
      const {findAllByText} = render(<RubricTab {...props} />)
      expect((await findAllByText('Criteria'))[1]).toBeInTheDocument()
    })

    it('contains the rubric ratings heading', async () => {
      const props = await makeProps({graded: false})
      const {findAllByText} = render(<RubricTab {...props} />)
      expect((await findAllByText('Ratings'))[1]).toBeInTheDocument()
    })

    it('contains the rubric points heading', async () => {
      const props = await makeProps({graded: false})
      const {findAllByText} = render(<RubricTab {...props} />)
      expect((await findAllByText('Pts'))[1]).toBeInTheDocument()
    })
  })

  describe('graded rubric', () => {
    it('displays comments', async () => {
      const props = await makeProps({graded: true})
      const {findAllByText} = render(<RubricTab {...props} />)
      expect((await findAllByText('Comments'))[0]).toBeInTheDocument()
    })

    it('displays the points for a criteria', async () => {
      const props = await makeProps({graded: true})
      const {findByText} = render(<RubricTab {...props} />)
      expect(await findByText('6 / 6 pts')).toBeInTheDocument()
    })

    it('displays the total points for the rubric assessment', async () => {
      const props = await makeProps({graded: true})
      const {findByText} = render(<RubricTab {...props} />)
      expect(await findByText('Total Points: 5')).toBeInTheDocument()
    })

    it('displays the name of the assessor if present', async () => {
      const props = await makeProps({graded: true})
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('assessor1')).toBeInTheDocument()
    })

    it('displays the assessor enrollment if present', async () => {
      const props = await makeProps({graded: true})
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('assessor2 (TA)')).toBeInTheDocument()
    })

    it('displays "Anonymous" if the assessor is hidden', async () => {
      const props = await makeProps({graded: true})
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('Anonymous')).toBeInTheDocument()
    })

    it('changes the score when selecting a different assessor', async () => {
      const props = await makeProps({graded: true})
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)

      expect(await findByText('Total Points: 5')).toBeInTheDocument()
      fireEvent.click(await findByLabelText('Select Grader'))
      fireEvent.click(await findByText('Anonymous'))
      expect(await findByText('Total Points: 10')).toBeInTheDocument()
    })
  })
})

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
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import RubricTab from '../RubricTab'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {transformRubricData, transformRubricAssessmentData} from '../../helpers/RubricHelpers'

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
        outcomeProficiency: {
          proficiencyRatingsConnection: {
            nodes: [{}]
          }
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
        outcomeProficiency: {
          proficiencyRatingsConnection: null
        }
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
  const assessments = result.data.submission.rubricAssessmentsConnection?.nodes
  return {
    assessments: assessments?.map(assessment => transformRubricAssessmentData(assessment)),
    proficiencyRatings:
      result.data.course.account.outcomeProficiency?.proficiencyRatingsConnection?.nodes,
    rubric: transformRubricData(result.data.assignment.rubric)
  }
}

describe('RubricTab', () => {
  describe('ungraded rubric', () => {
    it('is collapsed by default', async () => {
      const props = await makeProps({graded: false})
      const {queryByText} = render(<RubricTab {...props} />)

      expect(queryByText('Criteria')).not.toBeInTheDocument()
    })

    describe('when expanded', () => {
      it('contains the rubric criteria heading', async () => {
        const props = await makeProps({graded: false})
        const {findAllByText, getByRole} = render(<RubricTab {...props} />)
        fireEvent.click(getByRole('button', {name: /View Rubric/}))

        expect((await findAllByText('Criteria'))[1]).toBeInTheDocument()
      })

      it('contains the rubric ratings heading', async () => {
        const props = await makeProps({graded: false})
        const {findAllByText, getByRole} = render(<RubricTab {...props} />)
        fireEvent.click(getByRole('button', {name: /View Rubric/}))

        expect((await findAllByText('Ratings'))[1]).toBeInTheDocument()
      })

      it('contains the rubric points heading', async () => {
        const props = await makeProps({graded: false})
        const {findAllByText, getByRole} = render(<RubricTab {...props} />)
        fireEvent.click(getByRole('button', {name: /View Rubric/}))

        expect((await findAllByText('Pts'))[1]).toBeInTheDocument()
      })

      it('shows possible points if the association does not hide points', async () => {
        const props = await makeProps({graded: false})
        props.rubricAssociation = {}

        const {findByText, getByRole} = render(<RubricTab {...props} />)
        fireEvent.click(getByRole('button', {name: /View Rubric/}))

        expect(await findByText(/\/ 6 pts/)).toBeInTheDocument()
      })

      it('does not show possible points for criteria if the association hides points', async () => {
        const props = await makeProps({graded: false})
        props.rubricAssociation = {hide_points: true}

        const {queryByText, getByRole} = render(<RubricTab {...props} />)
        fireEvent.click(getByRole('button', {name: /View Rubric/}))

        expect(queryByText(/\/ 6 pts/)).not.toBeInTheDocument()
      })
    })
  })

  describe('graded rubric', () => {
    it('displays comments', async () => {
      const props = await makeProps({graded: true})
      const {findAllByText} = render(<RubricTab {...props} />)
      expect((await findAllByText('Comments'))[0]).toBeInTheDocument()
    })

    it('displays the points for an individual criterion', async () => {
      const props = await makeProps({graded: true})
      const {findByText} = render(<RubricTab {...props} />)
      expect(await findByText('6 / 6 pts')).toBeInTheDocument()
    })

    it('hides the points for an individual criterion if the association hides points', async () => {
      const props = await makeProps({graded: true})
      props.rubricAssociation = {hide_points: true}

      const {queryByText} = render(<RubricTab {...props} />)
      expect(queryByText('6 / 6 pts')).not.toBeInTheDocument()
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

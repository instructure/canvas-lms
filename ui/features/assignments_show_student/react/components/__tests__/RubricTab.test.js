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
import $ from 'jquery'
import RubricTab from '../RubricTab'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {transformRubricData, transformRubricAssessmentData} from '../../helpers/RubricHelpers'
import store from '../stores'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

function gradedOverrides() {
  return {
    Submission: {
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 1,
            score: 5,
            assessor: {_id: 1, name: 'assessor1', enrollments: []},
          },
          {
            _id: 2,
            score: 10,
            assessor: null,
          },
          {
            _id: 3,
            score: 8,
            assessor: {_id: 2, name: 'assessor2', enrollments: [{type: 'TaEnrollment'}]},
          },
        ],
      },
    },
    Course: {
      account: {
        outcomeProficiency: {
          proficiencyRatingsConnection: {
            nodes: [{}],
          },
        },
      },
    },
  }
}

function ungradedOverrides() {
  return {
    Submission: {rubricAssessmentsConnection: null},
    Course: {
      account: {
        outcomeProficiency: {
          proficiencyRatingsConnection: null,
        },
      },
    },
  }
}

async function makeProps(opts = {}) {
  const variables = {
    courseID: '1',
    assignmentLid: '1',
    submissionID: '1',
    submissionAttempt: 0,
  }

  const overrides = opts.graded ? gradedOverrides() : ungradedOverrides()
  const allOverrides = [
    {
      Node: {__typename: 'Assignment'},
      Assignment: {rubric: {}},
      Rubric: {
        criteria: [{}],
      },
      ...overrides,
    },
  ]

  const result = await mockQuery(RUBRIC_QUERY, allOverrides, variables)
  const assessments = result.data.submission.rubricAssessmentsConnection?.nodes
  return {
    assessments: assessments?.map(assessment => transformRubricAssessmentData(assessment)) || [],
    proficiencyRatings:
      result.data.course.account.outcomeProficiency?.proficiencyRatingsConnection?.nodes,
    rubric: transformRubricData(result.data.assignment.rubric),
  }
}

function makeStore(props) {
  const assessment = props.peerReviewModeEnabled
    ? props.assessments?.find(assessment => assessment.assessor?._id === ENV.current_user.id)
    : props.assessments?.[0]
  const displayedAssessment = fillAssessment(props.rubric, assessment || {})
  store.setState({displayedAssessment})
}
const originalENV = window.ENV

describe('RubricTab', () => {
  beforeEach(() => {
    $.screenReaderFlashMessage = jest.fn()
    window.ENV = {...originalENV, current_user: {id: '2'}}
  })

  afterEach(() => {
    jest.restoreAllMocks()
    window.ENV = originalENV
  })

  describe('general', () => {
    it('contains "View Rubric" when peer review mode is OFF', async () => {
      const props = await makeProps({graded: false})
      props.peerReviewModeEnabled = false
      const {findByText, queryByText} = render(<RubricTab {...props} />)

      expect(await findByText('View Rubric')).toBeInTheDocument()
      expect(await queryByText('Fill Out Rubric')).not.toBeInTheDocument()
    })

    it('contains "Fill Out Rubric" when peer review mode is ON', async () => {
      const props = await makeProps({graded: false})
      props.peerReviewModeEnabled = true
      makeStore(props)
      const {findByText, queryByText} = render(<RubricTab {...props} />)

      expect(await findByText('Fill Out Rubric')).toBeInTheDocument()
      expect(await queryByText('View Rubric')).not.toBeInTheDocument()
    })

    it('disables interactions in the Rubric component by default', async () => {
      const props = await makeProps({graded: false})
      props.rubric.criteria[0].ratings[0].points = 9
      makeStore(props)
      const {findByText, queryByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByText(`9 pts`))
      expect(await queryByText(/^Total Points: 9 out of/)).not.toBeInTheDocument()
    })
  })

  describe('peer reviews', () => {
    it('enables interactions in the Rubric component by default', async () => {
      const props = await makeProps({graded: false})
      props.peerReviewModeEnabled = true
      props.rubric.criteria[0].ratings[0].points = 9
      makeStore(props)
      const {findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByText(`9 pts`))
      expect(await findByText(/^Total Points: 9 out of/)).toBeInTheDocument()
    })

    it('hides the grader selector', async () => {
      const props = await makeProps({graded: true})
      props.peerReviewModeEnabled = true
      makeStore(props)
      const {queryByText} = render(<RubricTab {...props} />)
      expect(await queryByText('Select Grader')).not.toBeInTheDocument()
    })

    it('sets displayed assessment as the assessment of the reviewer', async () => {
      const props = await makeProps({graded: true})
      props.peerReviewModeEnabled = true
      makeStore(props)
      const {findByText} = render(<RubricTab {...props} />)
      expect(await findByText('Total Points: 8')).toBeInTheDocument()
    })

    it('shows alert explaining that the rubric needs to be filled out to complete the review', async () => {
      const props = await makeProps({graded: false})
      props.peerReviewModeEnabled = true
      const {findByText} = render(<RubricTab {...props} />)

      expect(
        await findByText(
          'Fill out the rubric below after reviewing the student submission to complete this review.'
        )
      ).toBeInTheDocument()
    })

    it('does not display alert explaining that the rubric needs to be filled out if already completed ', async () => {
      const props = await makeProps({graded: false})
      props.peerReviewModeEnabled = true
      const assessment = {_id: '1', assessor: {_id: '1'}}
      props.assessments = [assessment]
      window.ENV.current_user.id = '1'
      const {queryByText} = render(<RubricTab {...props} />)

      expect(
        await queryByText(
          'Fill out the rubric below after reviewing the student submission to complete this review.'
        )
      ).not.toBeInTheDocument()
    })
  })

  describe('ungraded rubric', () => {
    it('contains the rubric ratings heading', async () => {
      const props = await makeProps({graded: false})
      makeStore(props)
      const {findAllByText} = render(<RubricTab {...props} />)

      expect((await findAllByText('Ratings'))[1]).toBeInTheDocument()
    })

    it('contains the rubric points heading', async () => {
      const props = await makeProps({graded: false})
      makeStore(props)
      const {findAllByText} = render(<RubricTab {...props} />)

      expect((await findAllByText('Pts'))[1]).toBeInTheDocument()
    })

    it('shows possible points if the association does not hide points', async () => {
      const props = await makeProps({graded: false})
      props.rubricAssociation = {_id: '1', hide_score_total: false, use_for_grading: false}
      makeStore(props)

      const {findByText} = render(<RubricTab {...props} />)

      expect(await findByText(/\/ 6 pts/)).toBeInTheDocument()
    })

    it('does not show possible points for criteria if the association hides points', async () => {
      const props = await makeProps({graded: false})
      props.rubricAssociation = {
        _id: '1',
        hide_score_total: false,
        use_for_grading: false,
        hide_points: true,
      }
      makeStore(props)

      const {queryByText} = render(<RubricTab {...props} />)

      expect(queryByText(/\/ 6 pts/)).not.toBeInTheDocument()
    })
  })

  describe('graded rubric', () => {
    let props
    beforeEach(async () => {
      props = await makeProps({graded: true})
      makeStore(props)
    })

    afterEach(() => {
      props = null
    })

    it('displays comments', async () => {
      const {findAllByText} = render(<RubricTab {...props} />)
      expect((await findAllByText('Comments'))[0]).toBeInTheDocument()
    })

    it('displays the points for an individual criterion', async () => {
      const {findByText} = render(<RubricTab {...props} />)
      expect(await findByText('6 / 6 pts')).toBeInTheDocument()
    })

    it('hides the points for an individual criterion if the association hides points', async () => {
      props.rubricAssociation = {
        _id: '1',
        hide_score_total: false,
        use_for_grading: false,
        hide_points: true,
      }

      const {queryByText} = render(<RubricTab {...props} />)
      expect(queryByText('6 / 6 pts')).not.toBeInTheDocument()
    })

    it('displays the total points for the rubric assessment', async () => {
      const {findByText} = render(<RubricTab {...props} />)
      expect(await findByText('Total Points: 5')).toBeInTheDocument()
    })

    it('displays the name of the assessor if present', async () => {
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('assessor1')).toBeInTheDocument()
    })

    it('displays the assessor enrollment if present', async () => {
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('assessor2 (TA)')).toBeInTheDocument()
    })

    it('displays "Anonymous" if the assessor is hidden', async () => {
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('Anonymous')).toBeInTheDocument()
    })

    it('changes the score when selecting a different assessor', async () => {
      const {findByLabelText, findByText} = render(<RubricTab {...props} />)

      expect(await findByText('Total Points: 5')).toBeInTheDocument()
      fireEvent.click(await findByLabelText('Select Grader'))
      fireEvent.click(await findByText('Anonymous'))
      expect(await findByText('Total Points: 10')).toBeInTheDocument()
    })
  })
})

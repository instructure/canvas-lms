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
import {MockedQueryProvider} from '@canvas/test-utils/query'
import React from 'react'
import $ from 'jquery'
import RubricTab from '../RubricTab'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {transformRubricData, transformRubricAssessmentData} from '../../helpers/RubricHelpers'
import store from '../stores'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

function gradedResolvers() {
  return {
    Submission: {
      rubricAssessmentsConnection: () => ({
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
      }),
    },
    Course: {
      account: {
        outcomeProficiency: {
          proficiencyRatingsConnection: () => ({
            nodes: [{}],
          }),
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

  const resolvers = opts.graded ? gradedResolvers() : {}
  const allOverrides = [
    {
      Node: {__typename: 'Assignment'},
      Assignment: {rubric: {}},
      Rubric: {
        criteria: [{}],
      },
    },
  ]

  const result = await mockQuery(RUBRIC_QUERY, allOverrides, variables, resolvers)
  const assessments = result.data.submission.rubricAssessmentsConnection?.nodes
  return {
    assessments: assessments?.map(assessment => transformRubricAssessmentData(assessment)) || [],
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

const renderRubricTab = props => {
  return render(
    <MockedQueryProvider>
      <RubricTab {...props} />
    </MockedQueryProvider>,
  )
}

describe('RubricTab - Graded Rubric Tests', () => {
  let props

  beforeEach(async () => {
    $.screenReaderFlashMessage = vi.fn()
    window.ENV = {...originalENV, current_user: {id: '2'}}
    props = await makeProps({graded: true})
    makeStore(props)
  })

  afterEach(() => {
    vi.restoreAllMocks()
    window.ENV = originalENV
    props = null
  })

  it('displays comments', async () => {
    const {findAllByText} = renderRubricTab(props)
    expect((await findAllByText('Comments'))[0]).toBeInTheDocument()
  })

  it('displays the points for an individual criterion', async () => {
    const {findByText} = renderRubricTab(props)
    expect(await findByText('6 / 6 pts')).toBeInTheDocument()
  })

  it('hides the points for an individual criterion if the association hides points', async () => {
    props.rubricAssociation = {
      _id: '1',
      hide_score_total: false,
      use_for_grading: false,
      hide_points: true,
    }

    const {queryByText} = renderRubricTab(props)
    expect(queryByText('6 / 6 pts')).not.toBeInTheDocument()
  })

  it('displays the total points for the rubric assessment', async () => {
    const {findByText} = renderRubricTab(props)
    expect(await findByText('Total Points: 5')).toBeInTheDocument()
  })

  it('displays the name of the assessor if present', async () => {
    const {findByLabelText, findByText} = renderRubricTab(props)
    fireEvent.click(await findByLabelText('Select Grader'))
    expect(await findByText('assessor1')).toBeInTheDocument()
  })

  it('displays the assessor enrollment if present', async () => {
    const {findByLabelText, findByText} = renderRubricTab(props)
    fireEvent.click(await findByLabelText('Select Grader'))
    expect(await findByText('assessor2 (TA)')).toBeInTheDocument()
  })

  it('displays "Anonymous" if the assessor is hidden', async () => {
    const {findByLabelText, findByText} = renderRubricTab(props)
    fireEvent.click(await findByLabelText('Select Grader'))
    expect(await findByText('Anonymous')).toBeInTheDocument()
  })

  it('changes the score when selecting a different assessor', async () => {
    const {findByLabelText, findByText} = renderRubricTab(props)

    expect(await findByText('Total Points: 5')).toBeInTheDocument()
    fireEvent.click(await findByLabelText('Select Grader'))
    fireEvent.click(await findByText('Anonymous'))
    expect(await findByText('Total Points: 10')).toBeInTheDocument()
  })

  describe('enhanced rubrics', () => {
    beforeAll(() => {
      window.ENV.enhanced_rubrics_enabled = true
    })

    afterAll(() => {
      window.ENV.enhanced_rubrics_enabled = false
    })

    it('displays the name of the assessor if present', async () => {
      const {findByLabelText, findByText} = renderRubricTab(props)
      fireEvent.click(await findByLabelText('Select Grader'))
      expect(await findByText('assessor1')).toBeInTheDocument()
    })

    it('displays in preview mode', () => {
      const {getByTestId} = renderRubricTab(props)
      const assessmentData = props.assessments[0].data[0]
      const {criterion_id} = assessmentData
      const commentSection = getByTestId('comment-preview-text-area')
      expect(commentSection).toHaveTextContent(assessmentData.comments)
      const ratingSection = getByTestId(`traditional-criterion-${criterion_id}-ratings-0`)
      expect(ratingSection).toBeDisabled()
    })
  })
})

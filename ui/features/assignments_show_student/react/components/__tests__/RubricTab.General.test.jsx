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
import {fireEvent, render, waitFor} from '@testing-library/react'
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

const ungradedResolvers = {
  Submission: {rubricAssessmentsConnection: () => []},
  Course: {
    account: {
      outcomeProficiency: {
        proficiencyRatingsConnection: () => null,
      },
    },
  },
}

const allOverrides = [
  {
    Node: {__typename: 'Assignment'},
    Assignment: {rubric: {}},
    Rubric: {
      criteria: [{}],
    },
  },
]

async function makeProps(opts = {}) {
  const variables = {
    courseID: '1',
    assignmentLid: '1',
    submissionID: '1',
    submissionAttempt: 0,
  }

  const resolvers = opts.graded ? {} : ungradedResolvers
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

describe('RubricTab - General Tests', () => {
  beforeAll(() => {
    window.ENV = {...originalENV, current_user: {id: '2'}}
  })

  beforeEach(() => {
    $.screenReaderFlashMessage = vi.fn()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  afterAll(() => {
    window.ENV = originalENV
  })

  it('displays correct button text based on peer review mode', async () => {
    const props = await makeProps({graded: false})

    // Test non-peer review mode
    props.peerReviewModeEnabled = false
    const {findByText, queryByText, rerender} = renderRubricTab(props)

    await waitFor(() => expect(findByText('View Rubric')).resolves.toBeInTheDocument())
    expect(queryByText('Fill Out Rubric')).not.toBeInTheDocument()

    // Test peer review mode
    props.peerReviewModeEnabled = true
    makeStore(props)
    rerender(
      <MockedQueryProvider>
        <RubricTab {...props} />
      </MockedQueryProvider>,
    )

    await waitFor(() => expect(findByText('Fill Out Rubric')).resolves.toBeInTheDocument())
    expect(queryByText('View Rubric')).not.toBeInTheDocument()
  })

  it('disables interactions in the Rubric component by default', async () => {
    const props = await makeProps({graded: false})
    props.rubric.criteria[0].ratings[0].points = 9
    makeStore(props)
    const {findByText, queryByText} = renderRubricTab(props)

    fireEvent.click(await findByText(`9 pts`))
    expect(queryByText(/^Total Points: 9 out of/)).not.toBeInTheDocument()
  })

  describe('enhanced rubrics', () => {
    beforeAll(() => {
      window.ENV.enhanced_rubrics_enabled = true
    })

    afterAll(() => {
      window.ENV.enhanced_rubrics_enabled = false
    })

    it('displays correct button text in enhanced mode', async () => {
      const props = await makeProps({graded: false})

      // Non-peer review
      props.peerReviewModeEnabled = false
      const {findByText, queryByText, rerender} = renderRubricTab(props)
      await waitFor(() => expect(findByText('View Rubric')).resolves.toBeInTheDocument())
      expect(queryByText('Fill Out Rubric')).not.toBeInTheDocument()

      // Peer review
      props.peerReviewModeEnabled = true
      makeStore(props)
      rerender(
        <MockedQueryProvider>
          <RubricTab {...props} />
        </MockedQueryProvider>,
      )
      await waitFor(() => expect(findByText('Fill Out Rubric')).resolves.toBeInTheDocument())
      expect(queryByText('View Rubric')).not.toBeInTheDocument()
    })
  })
})

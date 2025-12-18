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
import {render} from '@testing-library/react'
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

function ungradedResolvers() {
  return {
    Submission: {rubricAssessmentsConnection: () => []},
    Course: {
      account: {
        outcomeProficiency: {
          proficiencyRatingsConnection: () => null,
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

  const resolvers = ungradedResolvers()
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

describe('RubricTab - Ungraded Rubric', () => {
  beforeEach(() => {
    $.screenReaderFlashMessage = vi.fn()
    window.ENV = {...originalENV, current_user: {id: '2'}}
  })

  afterEach(() => {
    vi.restoreAllMocks()
    window.ENV = originalENV
  })

  it('contains the rubric ratings heading', async () => {
    const props = await makeProps({graded: false})
    makeStore(props)
    const {findAllByText} = renderRubricTab(props)

    expect((await findAllByText('Ratings'))[1]).toBeInTheDocument()
  })

  it('contains the rubric points heading', async () => {
    const props = await makeProps({graded: false})
    makeStore(props)
    const {findAllByText} = renderRubricTab(props)

    expect((await findAllByText('Pts'))[1]).toBeInTheDocument()
  })

  it('shows possible points if the association does not hide points', async () => {
    const props = await makeProps({graded: false})
    props.rubricAssociation = {_id: '1', hide_score_total: false, use_for_grading: false}
    makeStore(props)

    const {findByText} = renderRubricTab(props)

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

    const {queryByText} = renderRubricTab(props)

    expect(queryByText(/\/ 6 pts/)).not.toBeInTheDocument()
  })
})

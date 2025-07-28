/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import CheckpointGradeContainer from '../CheckpointGradeContainer'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'

const defaultProps = (assignmentOverrides?: any) => ({
  assignment: {
    grading_type: 'points',
    total_score: '20',
    checkpoint_submissions: [
      {
        tag: 'reply_to_topic',
        submission_id: '2',
        points_possible: '10',
        submission_score: 10,
      },
      {
        tag: 'reply_to_entry',
        submission_id: '3',
        points_possible: '10',
        submission_score: 10,
      },
    ],
    ...assignmentOverrides,
  },
})

const renderComponent = (props = defaultProps()) => {
  return render(
    <ApolloProvider client={createClient()}>
      <CheckpointGradeContainer {...props} />
    </ApolloProvider>
  )
}

describe('CheckpointGradeContainer', () => {
  it('should render', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('checkpoint-grades-container')).toBeInTheDocument()
    expect(getByTestId('total-score-display')).toBeInTheDocument()
    expect(getByTestId('total-score-display')).toHaveValue('20')
  })

  it('renders "-" for total grade when total_score is null', () => {
    const props = defaultProps({total_score: ''})
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('total-score-display')).toHaveValue('-')
  })
})

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import StudentAnnotationAttempt from '../StudentAnnotationAttempt'
import {render} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,
    title: 'Title',
    createSubmissionDraft: jest.fn().mockResolvedValue({})
  }
  return props
}

describe('StudentAnnotationAttempt', () => {
  it('renders an iframe for canvadocs', async () => {
    const props = await makeProps({})
    const {getByTestId} = render(<StudentAnnotationAttempt {...props} />)
    expect(getByTestId('canvadocs-iframe')).toBeInTheDocument()
  })
})

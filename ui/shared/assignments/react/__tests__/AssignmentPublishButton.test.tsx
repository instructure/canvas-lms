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

import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import {render, screen} from '@testing-library/react'
import {mockAssignment, mockSetWorkflowSuccess, mockSetWorkflowFailure} from './test-utils'
import AssignmentPublishButton from '../AssignmentPublishButton'

const setUp = (propOverrides = {}, mockSuccess = true) => {
  const assignment = mockAssignment()
  const props = {
    isPublished: true,
    assignmentLid: assignment.lid,
    breakpoints: {},
    ...propOverrides,
  }
  const mocks = mockSuccess ? [mockSetWorkflowSuccess] : [mockSetWorkflowFailure]
  return render(
    <MockedProvider mocks={mocks} addTypename={false}>
      {/* @ts-expect-error */}
      <AssignmentPublishButton {...props} />
    </MockedProvider>,
  )
}

describe('AssignmentPublishButton', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders button with publish state if published', () => {
    const {getByTestId} = setUp()
    expect(getByTestId('assignment-publish-menu')).toBeInTheDocument()
    expect(getByTestId('assignment-publish-menu')).toHaveTextContent('Published')
  })

  it('renders button with unpublished state if unpublished', () => {
    const {getByTestId} = setUp({isPublished: false})
    expect(getByTestId('assignment-publish-menu')).toBeInTheDocument()
    expect(getByTestId('assignment-publish-menu')).toHaveTextContent('Unpublished')
  })

  it('renders success flash alert', async () => {
    const {getByTestId} = setUp()
    getByTestId('assignment-publish-menu').click()
    getByTestId('unpublish-option').click()
    const alertMessages = await screen.findAllByText('This assignment has been unpublished.')
    expect(alertMessages.length).toBeGreaterThan(0)
  })

  it('renders failure flash alert', async () => {
    const {getByTestId} = setUp({}, false)
    getByTestId('assignment-publish-menu').click()
    getByTestId('unpublish-option').click()
    const alertMessages = await screen.findAllByText('This assignment has failed to unpublish.')
    expect(alertMessages.length).toBeGreaterThan(0)
  })
})

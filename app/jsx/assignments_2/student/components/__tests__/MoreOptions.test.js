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

import {EXTERNAL_TOOLS_QUERY} from '../../graphqlData/Queries'
import {fireEvent, render, waitForElement, waitForElementToBeRemoved} from '@testing-library/react'
import {MockedProvider} from 'react-apollo/test-utils'
import {mockQuery} from '../../mocks'
import MoreOptions from '../MoreOptions'
import React from 'react'

async function createGraphqlMocks(overrides = {}) {
  const result = await mockQuery(EXTERNAL_TOOLS_QUERY, overrides, {courseID: '1'})
  return [
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'}
      },
      result
    }
  ]
}

describe('MoreOptions', () => {
  it('renders a button for more options', async () => {
    const {getByText} = render(<MoreOptions assignmentID="1" courseID="1" />)
    expect(getByText('More Options')).toBeInTheDocument()
  })

  it('renders the more options modal when the button is clicked', async () => {
    const mocks = await createGraphqlMocks()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" />
      </MockedProvider>
    )
    const moreOptionsButton = getByTestId('more-options-button')
    fireEvent.click(moreOptionsButton)

    expect(await waitForElement(() => getByTestId('more-options-modal'))).toBeInTheDocument()
  })

  it('renders the external tools in tabs', async () => {
    const overrides = {
      ExternalToolConnection: () => ({
        nodes: [{_id: '1', name: 'Tool 1'}, {_id: '2', name: 'Tool 2'}]
      })
    }
    const mocks = await createGraphqlMocks(overrides)
    const {getByTestId, getAllByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" />
      </MockedProvider>
    )
    const moreOptionsButton = getByTestId('more-options-button')
    fireEvent.click(moreOptionsButton)

    const tabs = await waitForElement(() => getAllByRole('tab'))
    expect(tabs[0]).toContainHTML('Tool 1')
    expect(tabs[1]).toContainHTML('Tool 2')
  })

  it('closes the modal when it receives the "LtiDeepLinkingResponse" event', async () => {
    const overrides = {
      ExternalToolConnection: () => ({
        nodes: [{_id: '1', name: 'Tool 1'}, {_id: '2', name: 'Tool 2'}]
      })
    }
    const mocks = await createGraphqlMocks(overrides)
    const {getByTestId, queryByTestId} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" />
      </MockedProvider>
    )
    const moreOptionsButton = getByTestId('more-options-button')
    fireEvent.click(moreOptionsButton)

    const modal = await waitForElement(() => getByTestId('more-options-modal'))
    expect(modal).toBeInTheDocument()

    fireEvent(window, new MessageEvent('message', {data: {messageType: 'LtiDeepLinkingResponse'}}))

    await waitForElementToBeRemoved(() => queryByTestId('more-options-modal'))
    expect(queryByTestId('more-options-modal')).not.toBeInTheDocument()
  })
})

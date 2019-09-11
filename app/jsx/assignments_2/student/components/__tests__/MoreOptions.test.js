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

import axios from 'axios'
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '../../graphqlData/Queries'
import {fireEvent, render, waitForElement} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '../../mocks'
import MoreOptions from '../AttemptType/MoreOptions'
import React from 'react'

jest.mock('axios')

async function createGraphqlMocks(overrides = {}) {
  const userGroupOverrides = [{Node: () => ({__typename: 'User'})}]
  userGroupOverrides.push(overrides)

  const externalToolsResult = await mockQuery(EXTERNAL_TOOLS_QUERY, overrides, {courseID: '1'})
  const userGroupsResult = await mockQuery(USER_GROUPS_QUERY, userGroupOverrides, {userID: '1'})
  return [
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'}
      },
      result: externalToolsResult
    },
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'}
      },
      result: externalToolsResult
    },
    {
      request: {
        query: USER_GROUPS_QUERY,
        variables: {userID: '1'}
      },
      result: userGroupsResult
    }
  ]
}

beforeAll(() => {
  axios.get.mockImplementation(input => {
    const resp = {headers: {}}
    if (input === '/api/v1/users/self/folders/root') {
      resp.data = {
        context_type: 'user',
        id: 1,
        name: 'my files'
      }
    } else if (input === '/api/v1/courses/1/folders/root') {
      resp.data = {
        context_type: 'course',
        id: 2,
        name: 'course files'
      }
    } else if (input === '/api/v1/groups/1/folders/root') {
      resp.data = {
        context_type: 'group',
        id: 3,
        name: 'group files'
      }
    }
    return Promise.resolve(resp)
  })
})

describe('MoreOptions', () => {
  it('renders a button for more options', () => {
    const {getByText} = render(
      <MockedProvider>
        <MoreOptions assignmentID="1" courseID="1" userID="1" />
      </MockedProvider>
    )
    expect(getByText('More Options')).toBeInTheDocument()
  })

  it('renders the more options modal when the button is clicked', async () => {
    const mocks = await createGraphqlMocks()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" />
      </MockedProvider>
    )
    const moreOptionsButton = getByTestId('more-options-button')
    fireEvent.click(moreOptionsButton)

    expect(await waitForElement(() => getByTestId('more-options-modal'))).toBeInTheDocument()
  })

  describe('LTI Tools', () => {
    it('renders the external tools in tabs', async () => {
      const overrides = {
        ExternalToolConnection: () => ({
          nodes: [{_id: '1', name: 'Tool 1'}, {_id: '2', name: 'Tool 2'}]
        })
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId, getAllByRole} = render(
        <MockedProvider mocks={mocks} addTypename>
          <MoreOptions assignmentID="1" courseID="1" userID="1" />
        </MockedProvider>
      )
      const moreOptionsButton = getByTestId('more-options-button')
      fireEvent.click(moreOptionsButton)

      const tabs = await waitForElement(() => getAllByRole('tab'))
      expect(tabs[1]).toContainHTML('Tool 1')
      expect(tabs[2]).toContainHTML('Tool 2')
    })

    it('closes the modal when it receives the "LtiDeepLinkingResponse" event', async () => {
      const overrides = {
        ExternalToolConnection: () => ({
          nodes: [{_id: '1', name: 'Tool 1'}, {_id: '2', name: 'Tool 2'}]
        })
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId, queryByTestId} = render(
        <MockedProvider mocks={mocks} addTypename>
          <MoreOptions assignmentID="1" courseID="1" userID="1" />
        </MockedProvider>
      )
      const moreOptionsButton = getByTestId('more-options-button')
      fireEvent.click(moreOptionsButton)

      const modal = await waitForElement(() => getByTestId('more-options-modal'))
      expect(modal).toBeInTheDocument()

      fireEvent(
        window,
        new MessageEvent('message', {data: {messageType: 'LtiDeepLinkingResponse'}})
      )

      expect(queryByTestId('more-options-modal')).not.toBeInTheDocument()
    })
  })

  describe('Canvas Files', () => {
    it('renders the canvas files tab', async () => {
      const overrides = {
        ExternalToolConnection: () => ({
          nodes: [{_id: '1', name: 'Tool 1'}, {_id: '2', name: 'Tool 2'}]
        })
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId, getAllByRole} = render(
        <MockedProvider mocks={mocks} addTypename>
          <MoreOptions assignmentID="1" courseID="1" userID="1" />
        </MockedProvider>
      )
      const moreOptionsButton = getByTestId('more-options-button')
      fireEvent.click(moreOptionsButton)

      const tabs = await waitForElement(() => getAllByRole('tab'))
      expect(tabs[0]).toContainHTML('Canvas Files')
    })

    it('renders user, group, and course folders', async () => {
      const overrides = {
        ExternalToolConnection: () => ({
          nodes: [{_id: '1', name: 'Tool 1'}, {_id: '2', name: 'Tool 2'}]
        })
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByText, getByTestId} = render(
        <MockedProvider mocks={mocks} addTypename>
          <MoreOptions assignmentID="1" courseID="1" userID="1" />
        </MockedProvider>
      )
      const moreOptionsButton = getByTestId('more-options-button')
      fireEvent.click(moreOptionsButton)

      expect(await waitForElement(() => getByText('my files'))).toBeInTheDocument()
      expect(await waitForElement(() => getByText('course files'))).toBeInTheDocument()
      expect(
        await waitForElement(() => getByText(mocks[2].result.data.legacyNode.groups[0].name))
      ).toBeInTheDocument()
    })
  })
})

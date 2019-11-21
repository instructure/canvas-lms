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

import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '../../../graphqlData/Queries'
import {fireEvent, render, wait} from '@testing-library/react'
import React from 'react'
import {mockAssignmentAndSubmission, mockQuery} from '../../../mocks'
import {MockedProvider} from '@apollo/react-testing'

import UrlEntry from '../UrlEntry'

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

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,
    createSubmissionDraft: jest.fn().mockResolvedValue({}),
    updateEditingDraft: jest.fn()
  }
  return props
}

describe('UrlEntry', () => {
  describe('unsubmitted', () => {
    it('renders the website url input', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: false,
            url: null
          }
        }
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByTestId('url-entry')).toBeInTheDocument()
    })

    it('renders the more options button', async () => {
      const props = await makeProps()
      const overrides = {
        ExternalToolConnection: {
          nodes: [{_id: '1', name: 'Tool 1'}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findByText} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(await findByText('More Options')).toBeInTheDocument()
    })

    it('renders an error message when given an invalid url', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: false,
            url: 'not a valid url'
          }
        }
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByText('Please enter a valid url (e.g. http://example.com)')).toBeInTheDocument()
    })

    it('renders the preview button when the url is considered valid', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: true,
            url: 'http://www.valid.com'
          }
        }
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByTestId('preview-button')).toBeInTheDocument()
    })

    it('opens a new window with the url when you press the preview button', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: true,
            url: 'http://www.reddit.com'
          }
        }
      })
      window.open = jest.fn()
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      const previewButton = getByTestId('preview-button')
      fireEvent.click(previewButton)
      expect(window.open).toHaveBeenCalledTimes(1)
    })

    it('updates the input and creates a draft from an LTI response', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const props = await makeProps()
      render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            messageType: 'LtiDeepLinkingResponse',
            content_items: [
              {
                url: 'http://lemon.com'
              }
            ]
          }
        })
      )

      await wait(() => {
        expect(props.createSubmissionDraft).toHaveBeenCalledWith({
          variables: {
            activeSubmissionType: 'online_url',
            id: '1',
            attempt: 1,
            url: 'http://lemon.com'
          }
        })
      })
    })
  })

  describe('submitted', () => {
    it('renders a link to the submitted url', async () => {
      const props = await makeProps({
        Submission: {
          attachment: {_id: '1'},
          state: 'submitted',
          url: 'http://www.google.com'
        }
      })
      const {getByText} = render(<UrlEntry {...props} />)

      expect(getByText('http://www.google.com')).toBeInTheDocument()
    })
  })
})

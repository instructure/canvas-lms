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

import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import StudentViewContext from '../../Context'

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
        variables: {courseID: '1'},
      },
      result: externalToolsResult,
    },
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'},
      },
      result: externalToolsResult,
    },
    {
      request: {
        query: USER_GROUPS_QUERY,
        variables: {userID: '1'},
      },
      result: userGroupsResult,
    },
  ]
}

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,
    createSubmissionDraft: jest.fn().mockResolvedValue({}),
    updateEditingDraft: jest.fn(),
    focusOnInit: false,
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
            url: null,
          },
        },
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByTestId('url-entry')).toBeInTheDocument()
    })

    it('renders the website url input as disabled for observers', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: false,
            url: null,
          },
        },
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
            <UrlEntry {...props} />
          </StudentViewContext.Provider>
        </MockedProvider>
      )

      expect(getByTestId('url-input')).toHaveAttribute('readonly')
    })

    it('moves focus to the website url input after render when focusOnInit is true', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: false,
            url: null,
          },
        },
      })
      props.focusOnInit = true
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByTestId('url-input')).toHaveFocus()
    })

    it('does not move focus to the website url input after render when focusOnInit is false', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: false,
            url: null,
          },
        },
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByTestId('url-input')).not.toHaveFocus()
    })

    it('renders an error message when given an invalid url', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: false,
            url: 'not a valid url',
          },
        },
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByText('Please enter a valid url (e.g. https://example.com)')).toBeInTheDocument()
    })

    it('renders the preview button when the url is considered valid', async () => {
      const props = await makeProps({
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_url',
            attachments: () => [],
            body: null,
            meetsUrlCriteria: true,
            url: 'http://www.valid.com',
          },
        },
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
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
            url: 'http://www.reddit.com',
          },
        },
      })
      window.open = jest.fn()
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
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
  })

  describe('submitted', () => {
    it('renders a link to the submitted url', async () => {
      const props = await makeProps({
        Submission: {
          attachment: {_id: '1'},
          state: 'submitted',
          url: 'http://www.google.com',
        },
      })
      const {getByText} = render(<UrlEntry {...props} />)

      expect(getByText('http://www.google.com')).toBeInTheDocument()
    })
  })

  describe('graded', () => {
    it('renders a link to the submitted url when graded post-submission', async () => {
      const props = await makeProps({
        Submission: {
          attachment: {_id: '1'},
          state: 'graded',
          attempt: 1,
          url: 'http://www.google.com',
        },
      })
      const {getByText} = render(<UrlEntry {...props} />)

      expect(getByText('http://www.google.com')).toBeInTheDocument()
    })

    it('renders the URL input when graded pre-submission', async () => {
      const props = await makeProps({
        Submission: {
          state: 'graded',
          attempt: 0,
        },
      })
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}],
        },
      }
      const mocks = await createGraphqlMocks(overrides)
      const {getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <UrlEntry {...props} />
        </MockedProvider>
      )

      expect(getByTestId('url-entry')).toBeInTheDocument()
    })
  })
})

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

import axios from '@canvas/axios'
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import MoreOptions from '../MoreOptions/index'
import React from 'react'

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

beforeEach(() => {
  jest.spyOn(axios, 'get').mockImplementation(input => {
    const resp = {headers: {}, data: []}
    if (input === '/api/v1/users/self/folders/root') {
      resp.data = {
        context_type: 'user',
        id: '1',
        name: 'my files',
        created_at: '2019-08-13T16:38:42Z'
      }
    } else if (input === '/api/v1/groups/1/folders/root') {
      resp.data = {
        context_type: 'group',
        id: '3',
        name: 'group files',
        created_at: '2019-08-13T16:38:42Z'
      }
    } else if (input === '/api/v1/folders/1/folders?include=user') {
      resp.data = {
        id: '4',
        name: 'dank memes',
        created_at: '2019-08-13T16:38:42Z',
        locked: false,
        parent_folder_id: '1'
      }
    } else if (input === '/api/v1/folders/4/files?include=user') {
      resp.data = {
        id: '10',
        display_name: 'bad_luck_brian.png',
        created_at: '2019-05-14T18:14:05Z',
        updated_at: '2019-08-14T22:26:07Z',
        user: {
          display_name: 'Mr. Norton'
        },
        size: 1122994,
        locked: false,
        folder_id: '4'
      }
    } else if (input === '/api/v1/folders/1/files?include=user') {
      resp.data = {
        id: '11',
        display_name: 'www.creedthoughts.gov.www/creedthoughts',
        created_at: '2019-05-14T20:00:00Z',
        updated_at: '2019-08-14T22:00:00Z',
        user: {
          display_name: 'Creed Bratton'
        },
        size: 1122994,
        locked: false,
        folder_id: '1'
      }
    }
    return Promise.resolve(resp)
  })
})

describe('MoreOptions', () => {
  it('renders a button for selecting Canvas files when handleCanvasFiles is not null', async () => {
    const overrides = {
      ExternalToolConnection: {
        nodes: [{}]
      }
    }

    const mocks = await createGraphqlMocks(overrides)
    const {findByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
      </MockedProvider>
    )
    expect(await findByRole('button', {name: /Files/})).toBeInTheDocument()
  })

  it('does not render a button for selecting Canvas files when handleCanvasFiles is null', async () => {
    const overrides = {
      ExternalToolConnection: {
        nodes: [{}]
      }
    }

    const mocks = await createGraphqlMocks(overrides)
    const {queryByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" />
      </MockedProvider>
    )
    expect(queryByRole('button', {name: /Files/})).not.toBeInTheDocument()
  })

  it('renders a button for each external tool that belongs to the course', async () => {
    const overrides = {
      ExternalToolConnection: {
        nodes: [
          {_id: '1', name: 'Tool 1'},
          {_id: '2', name: 'Tool 2'}
        ]
      }
    }

    const mocks = await createGraphqlMocks(overrides)
    const {findByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
      </MockedProvider>
    )
    expect(await findByRole('button', {name: /Tool 1/})).toBeInTheDocument()
    expect(await findByRole('button', {name: /Tool 2/})).toBeInTheDocument()
  })

  it('places the button for Canvas files before any external tools', async () => {
    const overrides = {
      ExternalToolConnection: {
        nodes: [
          {_id: '1', name: 'Tool 1'},
          {_id: '2', name: 'Tool 2'}
        ]
      }
    }

    const mocks = await createGraphqlMocks(overrides)
    const {findAllByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
      </MockedProvider>
    )

    const buttons = await findAllByRole('button')
    expect(buttons[0]).toHaveTextContent('Files')
    expect(buttons[1]).toHaveTextContent('Tool 1')
    expect(buttons[2]).toHaveTextContent('Tool 2')
  })

  describe('LTI Tools', () => {
    it('renders a modal for an external tool when its button is clicked', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [
            {_id: '1', name: 'Tool 1'},
            {_id: '2', name: 'Tool 2'}
          ]
        }
      }

      const mocks = await createGraphqlMocks(overrides)
      const {findByRole} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
        </MockedProvider>
      )

      const tool1 = await findByRole('button', {name: /Tool 1/})
      fireEvent.click(tool1)

      const modal = await findByRole('dialog')
      expect(modal).toContainHTML('Tool 1')
    })

    it('closes the modal when it receives the "LtiDeepLinkingResponse" event', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [
            {_id: '1', name: 'Tool 1'},
            {_id: '2', name: 'Tool 2'}
          ]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findByRole, queryByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
        </MockedProvider>
      )

      const tool1 = await findByRole('button', {name: /Tool 1/})
      fireEvent.click(tool1)

      const modal = await findByRole('dialog')
      expect(modal).toBeInTheDocument()

      fireEvent(
        window,
        new MessageEvent('message', {data: {messageType: 'LtiDeepLinkingResponse'}})
      )

      await waitFor(() => {
        expect(queryByTestId('upload-file-modal')).not.toBeInTheDocument()
      })
    })

    it('closes the modal when it receives the "A2ExternalContentReady" event', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [
            {_id: '1', name: 'Tool 1'},
            {_id: '2', name: 'Tool 2'}
          ]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findByRole, queryByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
        </MockedProvider>
      )

      const tool1 = await findByRole('button', {name: /Tool 1/})
      fireEvent.click(tool1)

      const modal = await findByRole('dialog')
      expect(modal).toBeInTheDocument()

      fireEvent(
        window,
        new MessageEvent('message', {data: {messageType: 'A2ExternalContentReady'}})
      )

      await waitFor(() => {
        expect(queryByTestId('upload-file-modal')).not.toBeInTheDocument()
      })
    })

    it('does not close the modal when it receives a different event', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [
            {_id: '1', name: 'Tool 1'},
            {_id: '2', name: 'Tool 2'}
          ]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findByRole, queryByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
        </MockedProvider>
      )

      const tool1 = await findByRole('button', {name: /Tool 1/})
      fireEvent.click(tool1)

      const modal = await findByRole('dialog')
      expect(modal).toBeInTheDocument()

      fireEvent(window, new MessageEvent('message', {data: {messageType: 'whatever'}}))

      expect(queryByTestId('upload-file-modal')).toBeInTheDocument()
    })
  })

  describe('Canvas Files', () => {
    let selectedCanvasFiles = []
    const handleCanvasFiles = fileID => {
      selectedCanvasFiles.push(fileID)
    }

    beforeEach(() => {
      selectedCanvasFiles = []
    })

    it('renders user and group folders', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findAllByText, findByRole} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      fireEvent.click(canvasFilesButton)

      expect((await findAllByText('my files'))[0]).toBeInTheDocument()
      expect(
        (await findAllByText(mocks[2].result.data.legacyNode.groups[0].name))[0]
      ).toBeInTheDocument()
    })

    it('renders the folder contents when a folder is selected', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findAllByText, findByRole, findByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      fireEvent.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      fireEvent.click(myFilesButton)

      const fileSelect = await findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement((await findAllByText('dank memes'))[0])
      expect(fileSelect).toContainElement(
        (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      )
    }, 10000)

    it('allows folder navigation through breadcrumbs', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findAllByText, findByRole, findByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      fireEvent.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      fireEvent.click(myFilesButton)

      const fileSelect = await findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement((await findAllByText('dank memes'))[0])

      const rootFolderBreadcrumbLink = (await findAllByText('Root'))[0]
      fireEvent.click(rootFolderBreadcrumbLink)

      expect((await findAllByText('my files'))[0]).toBeInTheDocument()
      expect(
        (await findAllByText(mocks[2].result.data.legacyNode.groups[0].name))[0]
      ).toBeInTheDocument()
    })

    it('hides the upload button until a file has been selected', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findAllByText, findByRole, findByText, queryByText} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      fireEvent.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      fireEvent.click(myFilesButton)

      const file = (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      expect(file).toBeInTheDocument()

      expect(queryByText('Upload')).not.toBeInTheDocument()

      fireEvent.click(file)
      expect(await findByText('Upload')).toBeInTheDocument()
    })

    it('calls the handleCanvasFiles prop function when the upload button is clicked', async () => {
      const overrides = {
        ExternalToolConnection: {
          nodes: [{}]
        }
      }
      const mocks = await createGraphqlMocks(overrides)
      const {findAllByText, findByRole} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      fireEvent.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      fireEvent.click(myFilesButton)

      const file = (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      fireEvent.click(file)

      const uploadButton = await findByRole('button', {name: 'Upload'})
      fireEvent.click(uploadButton)

      expect(selectedCanvasFiles).toEqual(['11'])
    })
  }, 10000)
})

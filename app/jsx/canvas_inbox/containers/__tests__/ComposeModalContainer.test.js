/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import * as uploadFileModule from 'jsx/shared/upload_file'
import {AlertManagerContext} from 'jsx/shared/components/AlertManager'
import ComposeModalContainer from '../ComposeModalContainer'
import {COURSES_QUERY} from '../../Queries'
import {CREATE_CONVERSATION} from '../../Mutations'
import {createCache} from '../../../canvas-apollo'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '../../mocks'
import React from 'react'
import {fireEvent, render, wait} from '@testing-library/react'
import waitForApolloLoading from '../../helpers/waitForApolloLoading'

beforeEach(() => {
  uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
  window.ENV = {
    current_user_id: '1',
    CONVERSATIONS: {
      ATTACHMENTS_FOLDER_ID: 1
    }
  }
})

const createGraphqlMocks = () => {
  const mocks = [
    {
      request: {
        query: COURSES_QUERY,
        variables: {
          userID: '1'
        },
        overrides: {
          Node: {
            __typename: 'User'
          }
        }
      }
    },
    {
      request: {
        query: CREATE_CONVERSATION,
        variables: {
          attachmentIds: [],
          body: 'Potato',
          contextCode: undefined,
          recipients: ['5'], // TODO: change this when we have an address book component
          subject: 'Potato Subject',
          groupConversation: true
        },
        overrides: {
          CreateConversationPayload: {
            errors: null
          }
        }
      }
    }
  ]

  const mockResults = Promise.all(
    mocks.map(async m => {
      const result = await mockQuery(m.request.query, m.request.overrides, m.request.variables)
      return {
        request: {query: m.request.query, variables: m.request.variables},
        result
      }
    })
  )
  return mockResults
}

const setup = async (setOnFailure = jest.fn(), setOnSuccess = jest.fn()) => {
  const mocks = await createGraphqlMocks()
  return render(
    <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
      <MockedProvider mocks={mocks} cache={createCache()}>
        <ComposeModalContainer open onDismiss={jest.fn()} />
      </MockedProvider>
    </AlertManagerContext.Provider>
  )
}

describe('ComposeModalContainer', () => {
  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  describe('rendering', () => {
    it('should render', async () => {
      const component = await setup()
      expect(component.container).toBeTruthy()
    })
  })

  describe('Attachments', () => {
    it('attempts to upload a file', async () => {
      uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'file1.jpg'}])
      const {getByTestId} = await setup()
      const fileInput = getByTestId('attachment-input')
      const file = new File(['foo'], 'file.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file])

      expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith([file], '/api/v1/folders/1/files')
    })

    it('allows uploading multiple files', async () => {
      uploadFileModule.uploadFiles.mockResolvedValue([
        {id: '1', name: 'file1.jpg'},
        {id: '2', name: 'file2.jpg'}
      ])
      const {getByTestId} = await setup()
      const fileInput = getByTestId('attachment-input')
      const file1 = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
      const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file1, file2])

      expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith(
        [file1, file2],
        '/api/v1/folders/1/files'
      )
    })
  })

  describe('Subject', () => {
    it('allows setting the subject', async () => {
      const {getByTestId} = await setup()
      const subjectInput = getByTestId('subject-input')
      fireEvent.click(subjectInput)
      fireEvent.change(subjectInput, {target: {value: 'Potato'}})
      expect(subjectInput.value).toEqual('Potato')
    })
  })

  describe('Body', () => {
    it('allows setting the body', async () => {
      const {getByTestId} = await setup()
      const bodyInput = getByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})
      expect(bodyInput.value).toEqual('Potato')
    })
  })

  describe('Send individual messages', () => {
    it('allows toggling the setting', async () => {
      const {getByTestId} = await setup()
      const checkbox = getByTestId('individual-message-checkbox')
      expect(checkbox.checked).toBe(false)

      fireEvent.click(checkbox)
      expect(checkbox.checked).toBe(true)

      fireEvent.click(checkbox)
      expect(checkbox.checked).toBe(false)
    })
  })

  describe('Course Select', () => {
    it('queries graphql for courses', async () => {
      const component = await setup()

      await waitForApolloLoading()

      const select = await component.findByTestId('course-select')
      fireEvent.click(select)

      // Hello World is default value for string fields in our gql mocks
      const selectOptions = await component.findAllByText('Hello World')
      expect(selectOptions.length).toBeGreaterThan(0)
    })
  })

  describe('Create Conversation', () => {
    it('allows creating conversations', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

      const component = await setup(jest.fn(), mockedSetOnSuccess)

      await waitForApolloLoading()

      // Set subject
      const subjectInput = component.getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'Potato Subject'}})

      // Set body
      const bodyInput = component.getByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)

      await waitForApolloLoading()
      await wait(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
    })
  })
})

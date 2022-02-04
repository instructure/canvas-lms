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

import {Course} from '../../../../graphql/Course'
import {Enrollment} from '../../../../graphql/Enrollment'
import {fireEvent, render, screen} from '@testing-library/react'
import {Group} from '../../../../graphql/Group'
import HeaderInputs from '../HeaderInputs'
import {responsiveQuerySizes} from '../../../../util/utils'
import React from 'react'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {ApolloProvider} from 'react-apollo'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('HeaderInputs', () => {
  const server = mswServer(handlers)
  const defaultProps = props => ({
    courses: {
      favoriteGroupsConnection: {
        nodes: [Group.mock()]
      },
      favoriteCoursesConnection: {
        nodes: [Course.mock()]
      },
      enrollments: [Enrollment.mock()]
    },
    onContextSelect: jest.fn(),
    onSelectedIdsChange: jest.fn(),
    onUserFilterSelect: jest.fn(),
    onUserNoteChange: jest.fn(),
    onSendIndividualMessagesChange: jest.fn(),
    onSubjectChange: jest.fn(),
    onRemoveMediaComment: jest.fn(),
    ...props
  })

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'}
    }))
  })

  beforeEach(() => {
    window.ENV = {
      CONVERSATIONS: {
        NOTES_ENABLED: false,
        CAN_ADD_NOTES_FOR_ACCOUNT: false
      }
    }
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
    server.close()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <HeaderInputs {...props} />
      </ApolloProvider>
    )
  }

  it('does not render faculty journal checkbox when needed env vars are falsy', async () => {
    const container = setup(defaultProps())
    expect(await container.queryByTestId('mediafaculty-message-checkbox-mobile')).toBeNull()
    expect(await container.queryByTestId('mediafaculty-message-checkbox')).toBeNull()
  })

  it('calls onUserNoteChange when faculty message checkbox is toggled', async () => {
    window.ENV = {
      CONVERSATIONS: {
        NOTES_ENABLED: true,
        CAN_ADD_NOTES_FOR_ACCOUNT: true,
        CAN_ADD_NOTES_FOR_COURSES: {1: true}
      }
    }
    const props = defaultProps()
    const container = setup(props)
    const checkbox = await container.getByTestId('faculty-message-checkbox')
    fireEvent.click(checkbox)
    expect(props.onUserNoteChange).toHaveBeenCalled()
  })

  it('calls onSelectedIdsChange when using the Address Book component', async () => {
    const props = defaultProps({addressBookContainerOpen: true})
    const container = setup(props)

    const input = await container.findByTestId('address-book-input')
    fireEvent.change(input, {target: {value: 'Fred'}})

    const items = await screen.findAllByTestId('address-book-item')
    fireEvent.mouseDown(items[0])

    expect(container.findAllByTestId('address-book-tag')).toBeTruthy()

    expect(props.onSelectedIdsChange).toHaveBeenCalledWith([
      {
        _id: '1',
        id: 'TWVzc2FnZWFibGVVc2VyLTQx',
        name: 'Frederick Dukes'
      }
    ])
  })

  describe('Media Comments', () => {
    it('does not render a media comment if one is not provided', () => {
      const container = setup(defaultProps())
      expect(container.queryByTestId('media-attachment')).toBeNull()
    })

    it('does render a media comment if one is provided', () => {
      const container = setup(defaultProps({mediaAttachmentTitle: 'I am Lord Lemon'}))
      expect(container.getByTestId('media-attachment')).toBeInTheDocument()
      expect(container.getByText('I am Lord Lemon')).toBeInTheDocument()
    })

    it('calls the onRemoveMediaComment callback when the remove media button is clicked', () => {
      const props = defaultProps({mediaAttachmentTitle: 'No really I am Lord Lemon'})
      const container = setup(props)
      const removeMediaButton = container.getByTestId('remove-media-attachment')
      fireEvent.click(removeMediaButton)
      expect(props.onRemoveMediaComment).toHaveBeenCalled()
    })
  })
})

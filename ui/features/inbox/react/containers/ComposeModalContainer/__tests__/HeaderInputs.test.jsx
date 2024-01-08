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
import {act, fireEvent, render, screen} from '@testing-library/react'
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
  responsiveQuerySizes: jest.fn(),
}))

describe('HeaderInputs', () => {
  const server = mswServer(handlers)
  const defaultProps = props => ({
    courses: {
      favoriteGroupsConnection: {
        nodes: [Group.mock()],
      },
      favoriteCoursesConnection: {
        nodes: [Course.mock()],
      },
      enrollments: [Enrollment.mock()],
    },
    onContextSelect: jest.fn(),
    onSelectedIdsChange: jest.fn(),
    onUserFilterSelect: jest.fn(),
    onUserNoteChange: jest.fn(),
    onSendIndividualMessagesChange: jest.fn(),
    onSubjectChange: jest.fn(),
    onRemoveMediaComment: jest.fn(),
    setUserNote: jest.fn(),
    ...props,
  })

  beforeAll(() => {
    server.listen()

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  beforeEach(() => {
    window.ENV = {
      CONVERSATIONS: {
        NOTES_ENABLED: false,
        CAN_ADD_NOTES_FOR_ACCOUNT: false,
      },
    }
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
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

  describe('Faculty Journal Entry Option', () => {
    beforeEach(() => {
      window.ENV = {
        CONVERSATIONS: {
          NOTES_ENABLED: true,
          CAN_ADD_NOTES_FOR_ACCOUNT: true,
          CAN_ADD_NOTES_FOR_COURSES: {1: true},
        },
      }
    })

    const mockedRecipient = (
      props = {id: 'MockedRecipient', courseID: '1', courseRole: 'StudentEnrollment'}
    ) => {
      return {
        _id: props.id,
        id: props.id,
        name: '5',
        commonCoursesInfo: [
          {
            courseID: props.courseID,
            courseRole: props.courseRole,
          },
        ],
      }
    }

    const defaultRecipientProps = () => ({
      activeCourseFilter: {contextID: 'course_1', contextName: 'course 1'},
      selectedRecipients: [mockedRecipient()],
    })

    it('does not render if no recipients are chosen', async () => {
      const recipientPropInfo = defaultRecipientProps()
      recipientPropInfo.selectedRecipients = []
      const props = defaultProps(recipientPropInfo)

      const container = setup(props)

      expect(container.queryByTestId('faculty-message-checkbox')).not.toBeInTheDocument()
    })

    it('renders if no course is chosen', async () => {
      const recipientPropInfo = defaultRecipientProps()
      recipientPropInfo.activeCourseFilter = undefined
      const props = defaultProps(recipientPropInfo)
      const container = setup(props)

      expect(container.queryByTestId('faculty-message-checkbox')).toBeInTheDocument()
    })

    it('does not render if CAN_AND_NOTES_FOR_ACCOUNT is false', async () => {
      window.ENV = {
        CONVERSATIONS: {
          CAN_ADD_NOTES_FOR_ACCOUNT: false,
        },
      }
      const recipientPropInfo = defaultRecipientProps()
      recipientPropInfo.activeCourseFilter = undefined
      const props = defaultProps(recipientPropInfo)
      const container = setup(props)

      expect(container.queryByTestId('faculty-message-checkbox')).not.toBeInTheDocument()
    })

    it('does not render if any recipient does not have a student enrollment in the shared course', async () => {
      const recipientPropInfo = defaultRecipientProps()
      recipientPropInfo.selectedRecipients.push(
        mockedRecipient({id: 'MockedRecipient-2', courseID: '1', courseRole: 'TeacherEnrollment'})
      )
      const props = defaultProps(recipientPropInfo)
      const container = setup(props)

      expect(container.queryByTestId('faculty-message-checkbox')).not.toBeInTheDocument()
    })

    it('does not render if sender does not have permission to send notes in selected course', async () => {
      window.ENV = {
        CONVERSATIONS: {
          NOTES_ENABLED: true,
          CAN_ADD_NOTES_FOR_ACCOUNT: false,
          CAN_ADD_NOTES_FOR_COURSES: {},
        },
      }
      const props = defaultProps(defaultRecipientProps())
      const container = setup(props)

      expect(container.queryByTestId('faculty-message-checkbox')).not.toBeInTheDocument()
    })

    it('does not render if sender is not a teacher in the same course as the recipient', async () => {
      window.ENV = {
        CONVERSATIONS: {
          NOTES_ENABLED: true,
          CAN_ADD_NOTES_FOR_ACCOUNT: false,
          CAN_ADD_NOTES_FOR_COURSES: {2: true},
        },
      }
      const props = defaultProps(defaultRecipientProps())
      const container = setup(props)

      expect(container.queryByTestId('faculty-message-checkbox')).not.toBeInTheDocument()
    })

    it('renders if sender is account admin and recipient is a student', async () => {
      window.ENV = {
        CONVERSATIONS: {
          NOTES_ENABLED: true,
          CAN_ADD_NOTES_FOR_ACCOUNT: true,
          CAN_ADD_NOTES_FOR_COURSES: {},
        },
      }
      const props = defaultProps(defaultRecipientProps())
      const container = setup(props)

      expect(await container.findByTestId('faculty-message-checkbox')).toBeInTheDocument()
    })

    it('renders if sender is a teacher and recipient is a student', async () => {
      window.ENV = {
        CONVERSATIONS: {
          NOTES_ENABLED: true,
          CAN_ADD_NOTES_FOR_ACCOUNT: false,
          CAN_ADD_NOTES_FOR_COURSES: {1: true},
        },
      }
      const props = defaultProps(defaultRecipientProps())
      const container = setup(props)

      expect(await container.findByTestId('faculty-message-checkbox')).toBeInTheDocument()
    })

    it('calls onUserNoteChange when faculty message checkbox is toggled', async () => {
      const props = defaultProps(defaultRecipientProps())
      const container = setup(props)

      const checkbox = await container.getByTestId('faculty-message-checkbox')
      fireEvent.click(checkbox)

      expect(props.onUserNoteChange).toHaveBeenCalled()
    })
  })

  it('calls onSelectedIdsChange when using the Address Book component', async () => {
    jest.useFakeTimers()
    const props = defaultProps({addressBookContainerOpen: true})
    const container = setup(props)
    const input = await container.findByTestId('address-book-input')
    fireEvent.change(input, {target: {value: 'Fred'}})

    // for debouncing
    await act(async () => jest.advanceTimersByTime(1000))
    const items = await screen.findAllByTestId('address-book-item')
    fireEvent.mouseDown(items[1])

    expect(container.findAllByTestId('address-book-tag')).toBeTruthy()
    expect(props.onSelectedIdsChange.mock.calls[0][0][0]._id).toBe('1')
  })
})

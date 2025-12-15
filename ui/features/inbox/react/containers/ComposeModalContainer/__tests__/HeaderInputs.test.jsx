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
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react'
import {Group} from '../../../../graphql/Group'
import HeaderInputs from '../HeaderInputs'
import {responsiveQuerySizes} from '../../../../util/utils'
import React from 'react'
import {setupServer} from 'msw/node'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '@canvas/msw/mswClient'
import {ApolloProvider} from '@apollo/client'

vi.mock('../../../../util/utils', async () => ({
  ...(await vi.importActual('../../../../util/utils')),
  responsiveQuerySizes: vi.fn(),
}))

describe('HeaderInputs', () => {
  const server = setupServer(...handlers)
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
    onContextSelect: vi.fn(),
    onSelectedIdsChange: vi.fn(),
    onUserFilterSelect: vi.fn(),
    onSendIndividualMessagesChange: vi.fn(),
    onSubjectChange: vi.fn(),
    onRemoveMediaComment: vi.fn(),
    ...props,
  })

  beforeAll(() => {
    server.listen()

    window.ENV = {
      ...window.ENV,
      current_user_id: '1',
    }

    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
      }
    })

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  afterEach(() => {
    vi.useRealTimers()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <HeaderInputs {...props} />
      </ApolloProvider>,
    )
  }

  describe('when restrict_student_access feature is enabled', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.restrict_student_access = true
    })

    afterAll(() => {
      delete window.ENV.FEATURES.restrict_student_access
    })

    describe('when user is a teacher', () => {
      beforeAll(() => {
        window.ENV.current_user_has_teacher_enrollment = true
      })

      afterAll(() => {
        delete window.ENV.current_user_has_teacher_enrollment
      })

      it('does not render checkbox for individual message to each recipient', () => {
        vi.useFakeTimers()
        const props = defaultProps({addressBookContainerOpen: true})
        const {queryByText} = setup(props)
        expect(queryByText('Send an individual message to each recipient')).not.toBeInTheDocument()
      })
    })

    describe('when user is a student', () => {
      beforeAll(() => {
        window.ENV.current_user_roles = ['student']
      })

      afterAll(() => {
        delete window.ENV.current_user_roles
      })

      it('does render checkbox for individual message to each recipient', () => {
        vi.useFakeTimers()
        const props = defaultProps({addressBookContainerOpen: true})
        const {getByText} = setup(props)
        expect(getByText('Send an individual message to each recipient')).toBeInTheDocument()
      })
    })
  })

  describe('when restrict_student_access feature is disabled', () => {
    it('does render checkbox for individual message to each recipient', () => {
      vi.useFakeTimers()
      const props = defaultProps({addressBookContainerOpen: true})
      const {getByText} = setup(props)
      expect(getByText('Send an individual message to each recipient')).toBeInTheDocument()
    })
  })

  // TODO: This test freezes in Vitest due to the 500ms setInterval polling in
  // AddressBookContainer that conflicts with fake timers. The debouncing mechanism
  // creates an infinite loop when advancing fake timers. Needs refactoring to use
  // a debounce function instead of setInterval polling.
  it.skip('calls onSelectedIdsChange when using the Address Book component', async () => {
    vi.useFakeTimers()
    const props = defaultProps({addressBookContainerOpen: true})
    const container = setup(props)
    const input = await container.findByTestId('compose-modal-header-address-book-input')
    fireEvent.change(input, {target: {value: 'Fred'}})

    // for debouncing
    await act(async () => vi.advanceTimersByTime(1000))
    const items = await screen.findAllByTestId('address-book-item')
    fireEvent.mouseDown(items[0])

    await waitFor(() => {
      expect(props.onSelectedIdsChange).toHaveBeenCalled()
    })
    expect(props.onSelectedIdsChange.mock.calls[0][0][0]._id).toBe('1')
  })
})

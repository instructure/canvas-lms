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
import {setupServer} from 'msw/node'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '@canvas/msw/mswClient'
import {ApolloProvider} from '@apollo/client'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
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
    onContextSelect: jest.fn(),
    onSelectedIdsChange: jest.fn(),
    onUserFilterSelect: jest.fn(),
    onSendIndividualMessagesChange: jest.fn(),
    onSubjectChange: jest.fn(),
    onRemoveMediaComment: jest.fn(),
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
        jest.useFakeTimers()
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
        jest.useFakeTimers()
        const props = defaultProps({addressBookContainerOpen: true})
        const {getByText} = setup(props)
        expect(getByText('Send an individual message to each recipient')).toBeInTheDocument()
      })
    })
  })

  describe('when restrict_student_access feature is disabled', () => {
    it('does render checkbox for individual message to each recipient', () => {
      jest.useFakeTimers()
      const props = defaultProps({addressBookContainerOpen: true})
      const {getByText} = setup(props)
      expect(getByText('Send an individual message to each recipient')).toBeInTheDocument()
    })
  })

  it('calls onSelectedIdsChange when using the Address Book component', async () => {
    jest.useFakeTimers()
    const props = defaultProps({addressBookContainerOpen: true})
    const container = setup(props)
    const input = await container.findByTestId('compose-modal-header-address-book-input')
    fireEvent.change(input, {target: {value: 'Fred'}})

    // for debouncing
    await act(async () => jest.advanceTimersByTime(1000))
    const items = await screen.findAllByTestId('address-book-item')
    fireEvent.mouseDown(items[1])

    expect(container.findAllByTestId('address-book-tag')).toBeTruthy()
    expect(props.onSelectedIdsChange.mock.calls[0][0][0]._id).toBe('1')
  })
})

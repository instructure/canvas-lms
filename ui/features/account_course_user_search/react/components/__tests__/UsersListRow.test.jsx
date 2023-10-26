/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {render, screen} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import UsersListRow, {determineToggleFunction, generateIcon, generateTitle} from '../UsersListRow'
import {PROVIDER, RECIPIENT} from '@canvas/temporary-enrollment/react/types'

function makeProps() {
  return {
    accountId: '1',
    user: {
      id: '1',
      name: 'foo',
      short_name: 'foo',
      sortable_name: 'foo',
      avatar_url: 'http://someurl',
    },
    roles: [{id: '19', label: 'Teacher', base_role_name: 'TeacherEnrollment'}],
    handleOpenEditUserDialog: jest.fn(),
    handleSubmitEditUserForm: jest.fn(),
    handleCloseEditUserDialog: jest.fn(),
    permissions: {
      can_add_temporary_enrollments: false,
      can_edit_temporary_enrollments: false,
      can_delete_temporary_enrollments: false,
      can_edit_users: true,
      can_manage_admin_users: true,
      can_masquerade: true,
      can_message_users: true,
    },
  }
}

function renderUsersListRowWithProps(props) {
  render(
    <table>
      <tbody>
        <UsersListRow {...props} />
      </tbody>
    </table>
  )
}

describe('UsersListRow', () => {
  let defaultProps

  beforeEach(() => {
    // ensures these props are reset before each test
    defaultProps = makeProps()
  })

  it('renders an avatar', () => {
    renderUsersListRowWithProps(defaultProps)
    const avatar = screen.getByText('foo').querySelector('span')

    expect(avatar.getAttribute('src')).toBe(defaultProps.user.avatar_url)
  })

  it('renders all tooltips when permissions true', async () => {
    renderUsersListRowWithProps(defaultProps)

    expect(screen.getAllByRole('tooltip').length).toBe(3)
  })

  it('renders no tooltips when permissions are false', async () => {
    const noPermission = {
      ...defaultProps,
      permissions: {
        ...defaultProps.permissions,
        can_edit_users: false,
        can_manage_admin_users: false,
        can_masquerade: false,
        can_message_users: false,
      },
    }

    renderUsersListRowWithProps(noPermission)

    expect(screen.queryByRole('tooltip')).toBeNull()
  })

  describe('temporary enrollments', () => {
    let temporaryEnrollmentProps

    beforeEach(() => {
      // enrollment providers
      fetchMock.get(
        '/api/v1/users/1/enrollments?state%5B%5D=active&state%5B%5D=invited&temporary_enrollment_providers=true',
        [
          {
            id: '47',
            course_id: '5',
            user: {
              id: '7',
              name: 'Provider Person',
            },
            start_at: '2019-09-26T00:00:00Z',
            end_at: '2019-09-27T23:59:59Z',
            type: 'TeacherEnrollment',
          },
        ]
      )

      // enrollment recipients
      fetchMock.get(
        '/api/v1/users/1/enrollments?state%5B%5D=active&state%5B%5D=invited&temporary_enrollment_recipients=true',
        [
          {
            id: '48',
            course_id: '5',
            user: {
              id: '2',
              name: 'Recipient Person',
            },
            start_at: '2019-09-26T00:00:00Z',
            end_at: '2019-09-27T23:59:59Z',
            type: 'TeacherEnrollment',
          },
        ]
      )

      // ensures these props are reset before each test
      temporaryEnrollmentProps = {
        ...defaultProps,
        permissions: {
          ...defaultProps.permissions,
          can_add_temporary_enrollments: true,
          can_edit_temporary_enrollments: true,
          can_delete_temporary_enrollments: true,
        },
      }

      // for the tests that look at the UsersListRow dom
      renderUsersListRowWithProps(temporaryEnrollmentProps)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    describe('generateTitle function', () => {
      it('returns correct title for PROVIDER role', () => {
        const title = generateTitle(PROVIDER, 'John Doe')

        expect(title).toEqual('John Doe’s Temporary Enrollment Recipients')
      })

      it('returns correct title for RECIPIENT role', () => {
        const title = generateTitle(RECIPIENT, 'Jane Smith')

        expect(title).toEqual('Jane Smith’s Temporary Enrollment Providers')
      })

      it('returns default title for unknown role', () => {
        const title = generateTitle('some_other_role', 'User Name')

        expect(title).toEqual('Assign temporary enrollments to User Name')
      })
    })

    describe('determineToggleFunction', () => {
      it('returns toggleFunction if defined', () => {
        const toggleFunction = () => {}
        const setEditModeFunction = () => {}
        const result = determineToggleFunction(toggleFunction, setEditModeFunction)

        expect(result).toBe(toggleFunction)
      })

      it('returns setEditModeFunction if toggleFunction is undefined', () => {
        const setEditModeFunction = () => {}
        const result = determineToggleFunction(undefined, setEditModeFunction)

        expect(result).toBe(setEditModeFunction)
      })

      it('returns undefined if both functions are undefined', () => {
        const result = determineToggleFunction(undefined, undefined)

        expect(result).toBeUndefined()
      })
    })

    it('renders all tooltips when permissions true', async () => {
      const tooltips = screen.getAllByRole('tooltip')

      expect(tooltips.length).toBe(5)
    })

    describe('SVG Icons for temporary enrollments', () => {
      it('renders provider icon correctly', async () => {
        const svgForProvider = await screen.findByRole('img', {
          name: /Provider of temporary enrollment, click to edit/i,
        })

        expect(svgForProvider).toBeInTheDocument()
        expect(svgForProvider).toBeInstanceOf(SVGSVGElement)
      })

      it('renders recipient icon correctly', async () => {
        const svgForRecipient = await screen.findByRole('img', {
          name: /Recipient of temporary enrollment, click to edit/i,
        })

        expect(svgForRecipient).toBeInTheDocument()
        expect(svgForRecipient).toBeInstanceOf(SVGSVGElement)
      })

      describe('generateIcon function', () => {
        it('returns correct color prop for PROVIDER role', () => {
          const providerIcon = generateIcon(PROVIDER)

          expect(providerIcon.props.color).toEqual('success')
        })

        it('returns correct color prop for RECIPIENT role', () => {
          const recipientIcon = generateIcon(RECIPIENT)

          expect(recipientIcon.props.color).toEqual('success')
        })

        it('returns undefined color prop for default role', () => {
          const defaultIcon = generateIcon('some_other_role')

          expect(defaultIcon.props.color).toBeUndefined()
        })
      })
    })
  })
})

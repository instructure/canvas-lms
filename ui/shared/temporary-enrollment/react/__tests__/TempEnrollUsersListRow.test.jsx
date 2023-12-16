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
import {PROVIDER, RECIPIENT} from '../types'
import TempEnrollUsersListRow, {generateIcon, generateTooltip} from '../TempEnrollUsersListRow'

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
    },
  }
}

function renderTempEnrollUsersListRowWithProps(props) {
  render(
    <table>
      <tbody>
        <TempEnrollUsersListRow {...props} />
      </tbody>
    </table>
  )
}

describe('TempEnrollUsersListRow', () => {
  let defaultProps

  beforeEach(() => {
    defaultProps = makeProps()
  })

  it.skip('renders an avatar', () => {
    renderTempEnrollUsersListRowWithProps(defaultProps)
    const avatar = screen.getByText('foo').querySelector('span')

    expect(avatar.getAttribute('src')).toBe(defaultProps.user.avatar_url)
  })

  it.skip('renders all tooltips when permissions true', async () => {
    renderTempEnrollUsersListRowWithProps(defaultProps)

    expect(screen.getAllByRole('tooltip').length).toBe(3)
  })

  it.skip('renders no tooltips when permissions are false', async () => {
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

    renderTempEnrollUsersListRowWithProps(noPermission)

    expect(screen.queryByRole('tooltip')).toBeNull()
  })

  describe('temporary enrollments', () => {
    let temporaryEnrollmentProps

    beforeEach(() => {
      // enrollment providers
      // fetchMock.get(`/api/v1/users/${defaultProps.user.id}/temporary_enrollment_status`, {
      //   is_provider: true,
      //   is_recipient: false,
      // })

      // enrollment recipients
      // fetchMock.get(`/api/v1/users/${defaultProps.user.id}/temporary_enrollment_status`, {
      //   is_provider: false,
      //   is_recipient: true,
      // })

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
      renderTempEnrollUsersListRowWithProps(temporaryEnrollmentProps)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    describe('generateTooltip function', () => {
      it.skip('returns correct tooltip for PROVIDER role', () => {
        const title = generateTooltip(PROVIDER, 'John Doe')
        expect(title).toEqual('Temporary Enrollment Recipients for John Doe')
      })

      it.skip('returns correct tooltip for RECIPIENT role', () => {
        const title = generateTooltip(RECIPIENT, 'Jane Smith')
        expect(title).toEqual('Temporary Enrollment Providers for Jane Smith')
      })

      it.skip('returns default tooltip for unknown role', () => {
        const title = generateTooltip('some_other_role', 'User Name')

        expect(title).toEqual('Find a recipient of Temporary Enrollments')
      })
    })

    it.skip('renders all tooltips when permissions true', async () => {
      const tooltips = screen.getAllByRole('tooltip')

      expect(tooltips.length).toBe(5)
    })

    describe('SVG Icons for temporary enrollments', () => {
      it.skip('renders provider icon correctly', async () => {
        const svgForProvider = await screen.findByRole('img', {
          name: /Provider of temporary enrollment, click to edit/i,
        })

        expect(svgForProvider).toBeInTheDocument()
        expect(svgForProvider).toBeInstanceOf(SVGSVGElement)
      })

      it.skip('renders recipient icon correctly', async () => {
        const svgForRecipient = await screen.findByRole('img', {
          name: /Recipient of temporary enrollment, click to edit/i,
        })

        expect(svgForRecipient).toBeInTheDocument()
        expect(svgForRecipient).toBeInstanceOf(SVGSVGElement)
      })

      describe('generateIcon function', () => {
        it.skip('returns correct color prop for PROVIDER role', () => {
          const providerIcon = generateIcon(PROVIDER)

          expect(providerIcon.props.color).toEqual('success')
        })

        it.skip('returns correct color prop for RECIPIENT role', () => {
          const recipientIcon = generateIcon(RECIPIENT)

          expect(recipientIcon.props.color).toEqual('success')
        })

        it.skip('returns undefined color prop for default role', () => {
          const defaultIcon = generateIcon('some_other_role')

          expect(defaultIcon.props.color).toBeUndefined()
        })
      })
    })
  })
})

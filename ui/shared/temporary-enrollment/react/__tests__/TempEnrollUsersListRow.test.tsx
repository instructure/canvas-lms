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
import {render, screen, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {type EnrollmentType, PROVIDER, RECIPIENT} from '../types'
import TempEnrollUsersListRow, {generateIcon, generateTooltipText} from '../TempEnrollUsersListRow'

describe('TempEnrollUsersListRow', () => {
  const defaultProps = {
    user: {
      id: '1',
      name: 'user1',
    },
    permissions: {
      can_add_teacher: true,
      can_add_ta: true,
      can_add_student: true,
      can_add_observer: true,
      can_add_designer: true,
      can_read_sis: true,
      can_allow_course_admin_actions: true,
      can_add_temporary_enrollments: true,
      can_edit_temporary_enrollments: true,
      can_delete_temporary_enrollments: true,
    },
    roles: [{id: '2', name: 'Student', label: 'student', base_role_name: 'StudentEnrollmnet'}],
  }

  const STATUS_URL = `/api/v1/users/${defaultProps.user.id}/temporary_enrollment_status`

  describe('helper functions', () => {
    describe('generateTooltipText', () => {
      it('returns correct tooltip for PROVIDER role', () => {
        const title = generateTooltipText(PROVIDER, 'John Doe')
        expect(title).toEqual('Manage Temporary Enrollment Recipients for John Doe')
      })

      it('returns correct tooltip for RECIPIENT role', () => {
        const title = generateTooltipText(RECIPIENT, 'Jane Smith')
        expect(title).toEqual('Manage Temporary Enrollment Providers for Jane Smith')
      })

      it('returns default tooltip for unknown role', () => {
        const title = generateTooltipText('some_other_role' as EnrollmentType, 'User Name')
        expect(title).toEqual('Create Temporary Enrollment Pairing for User Name')
      })
    })

    describe('generateIcon', () => {
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

  describe('render tooltips', () => {
    afterEach(() => {
      fetchMock.restore()
    })

    it('no icons', async () => {
      fetchMock.get(STATUS_URL, {is_provider: false, is_recipient: false, can_provide: false})
      const {queryByTestId} = render(<TempEnrollUsersListRow {...defaultProps} />)
      await waitFor(() => expect(queryByTestId('user-list-row-tooltip')).toBeNull())
    })

    it('only can provide', async () => {
      fetchMock.get(STATUS_URL, {is_provider: false, is_recipient: false, can_provide: true})
      const {findAllByText} = render(<TempEnrollUsersListRow {...defaultProps} />)
      expect(
        await findAllByText(`Create Temporary Enrollment Pairing for ${defaultProps.user.name}`),
      ).toBeTruthy()
    })

    it('only recipient', async () => {
      fetchMock.get(STATUS_URL, {is_provider: false, is_recipient: true, can_provide: false})
      const {findAllByText} = render(<TempEnrollUsersListRow {...defaultProps} />)
      expect(
        await findAllByText(`Manage Temporary Enrollment Providers for ${defaultProps.user.name}`),
      ).toBeTruthy()
    })

    it('can provide and is providing', async () => {
      fetchMock.get(STATUS_URL, {is_provider: true, is_recipient: false, can_provide: true})
      const {findAllByText} = render(<TempEnrollUsersListRow {...defaultProps} />)
      expect(
        await findAllByText(`Manage Temporary Enrollment Recipients for ${defaultProps.user.name}`),
      ).toBeTruthy()
    })

    it('can provide and is recipient', async () => {
      fetchMock.get(STATUS_URL, {is_provider: false, is_recipient: true, can_provide: true})
      const {findAllByText} = render(<TempEnrollUsersListRow {...defaultProps} />)
      expect(
        await findAllByText(`Create Temporary Enrollment Pairing for ${defaultProps.user.name}`),
      ).toBeTruthy()
      expect(
        await findAllByText(`Manage Temporary Enrollment Providers for ${defaultProps.user.name}`),
      ).toBeTruthy()
    })

    it('is providing and is recipient', async () => {
      fetchMock.get(STATUS_URL, {is_provider: true, is_recipient: true, can_provide: true})
      const {findAllByText} = render(<TempEnrollUsersListRow {...defaultProps} />)
      expect(
        await findAllByText(`Manage Temporary Enrollment Recipients for ${defaultProps.user.name}`),
      ).toBeTruthy()
      expect(
        await findAllByText(`Manage Temporary Enrollment Providers for ${defaultProps.user.name}`),
      ).toBeTruthy()
    })
  })

  describe('permissions', () => {
    afterEach(() => {
      fetchMock.restore()
    })

    beforeEach(() => {
      fetchMock.get(STATUS_URL, {is_provider: true, can_provide: true, is_recipient: true})
    })

    it('renders all tooltips when permissions true', async () => {
      const {findAllByTestId} = render(<TempEnrollUsersListRow {...defaultProps} />)
      expect((await findAllByTestId('user-list-row-tooltip'))).toHaveLength(2)
    })

    it('renders no tooltips when permissions are false', async () => {
      const noPermission = {
        ...defaultProps,
        permissions: {
          ...defaultProps.permissions,
          can_edit_users: false,
          can_allow_course_admin_actions: false,
          can_masquerade: false,
          can_message_users: false,
        },
      }
      const {queryByTestId} = render(<TempEnrollUsersListRow {...noPermission} />)
      await waitFor(() => expect(queryByTestId('user-list-row-tooltip')).toBeNull())
    })
  })

  describe.skip('skipping due to time crunch and need to revisit', () => {
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

    let defaultProps: any

    beforeEach(() => {
      defaultProps = makeProps()
    })

    it('renders an avatar', () => {
      render(<TempEnrollUsersListRow {...defaultProps} />)
      const avatar = screen.getByText('foo').querySelector('span')
      expect(avatar?.getAttribute('src')).toBe(defaultProps.user.avatar_url)
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
        render(<TempEnrollUsersListRow {...temporaryEnrollmentProps} />)
      })

      afterEach(() => {
        fetchMock.restore()
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
      })
    })
  })
})

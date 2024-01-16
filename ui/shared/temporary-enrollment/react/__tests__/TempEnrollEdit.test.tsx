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

import {
  getEnrollmentUserDisplayName,
  getRelevantUserFromEnrollment,
  groupEnrollmentsByPairingId,
  TempEnrollEdit,
} from '../TempEnrollEdit'
import React from 'react'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {type Enrollment, PROVIDER, RECIPIENT, type User} from '../types'

describe('TempEnrollEdit component', () => {
  let props: any

  window.confirm = jest.fn(() => true)

  beforeEach(() => {
    props = {
      enrollments: [
        {
          id: '1',
          course_id: '1',
          user: {
            name: 'Recipient User',
            avatar_url: 'https://someurl.com/avatar.png',
            id: '6789',
          },
          start_at: '2021-01-01T00:00:00Z',
          end_at: '2021-02-01T00:00:00Z',
          type: 'TeacherEnrollment',
        },
      ] as Enrollment[],
      user: {
        name: 'Provider User',
        avatar_url: 'https://someurl.com/avatar.png',
        id: '1234',
      },
      onEdit: jest.fn(),
      onDelete: jest.fn(),
      onAddNew: jest.fn(),
      enrollmentType: PROVIDER,
      tempEnrollPermissions: {
        canAdd: true,
        canDelete: true,
        canEdit: true,
      },
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component', () => {
    const {container} = render(<TempEnrollEdit {...props} />)

    expect(screen.getByText(props.user.name)).toBeInTheDocument()

    const avatar = container.querySelector('span > img')
    expect(avatar).toBeInTheDocument()
    expect(avatar).toHaveAttribute('src', props.user.avatar_url)

    const rpText = screen.getByText('PU')
    expect(rpText).toBeInTheDocument()
  })

  describe('table headers', () => {
    it('displays the provider’s table headers', () => {
      render(<TempEnrollEdit {...props} />)

      expect(screen.getByText('Recipient Name')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Period')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Type')).toBeInTheDocument()
      expect(screen.getByText('Temporary enrollment option links')).toBeInTheDocument()
    })

    it('displays the recipient’s table headers', () => {
      render(<TempEnrollEdit {...props} enrollmentType={RECIPIENT} />)

      expect(screen.getByText('Provider Name')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Period')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Type')).toBeInTheDocument()
      expect(screen.getByText('Temporary enrollment option links')).toBeInTheDocument()
    })

    it('does not display options links if permissions are not set', () => {
      const newProps = {
        ...props,
        tempEnrollPermissions: {
          ...props.tempEnrollPermissions,
          canEdit: false,
          canDelete: false,
        },
      }

      render(<TempEnrollEdit {...newProps} />)

      expect(screen.queryByText('Temporary enrollment option links')).not.toBeInTheDocument()
    })
  })

  describe('action button visibility based on permissions', () => {
    it('shows Edit and Delete buttons based on canEdit and canDelete', () => {
      render(<TempEnrollEdit {...props} />)

      expect(screen.getByTestId('edit-button')).toBeInTheDocument()
      expect(screen.getByTestId('delete-button')).toBeInTheDocument()
    })

    it('does not show Edit button based on canEdit being false', () => {
      const newProps = {
        ...props,
        tempEnrollPermissions: {
          ...props.tempEnrollPermissions,
          canEdit: false,
        },
      }

      render(<TempEnrollEdit {...newProps} />)

      expect(screen.queryByTestId('edit-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('delete-button')).toBeInTheDocument()
    })

    it('does not show Delete button based on canDelete being false', () => {
      const newProps = {
        ...props,
        tempEnrollPermissions: {
          ...props.tempEnrollPermissions,
          canDelete: false,
        },
      }

      render(<TempEnrollEdit {...newProps} />)

      expect(screen.getByTestId('edit-button')).toBeInTheDocument()
      expect(screen.queryByTestId('delete-button')).not.toBeInTheDocument()
    })

    it('shows "Add New" button based on canAdd and enrollmentType', () => {
      render(<TempEnrollEdit {...props} />)

      expect(screen.getByTestId('add-button')).toBeInTheDocument()
    })

    it('does not show "Add New" button based on recipient enrollmentType', () => {
      const newProps = {
        ...props,
        enrollmentType: RECIPIENT,
      }

      render(<TempEnrollEdit {...newProps} />)

      expect(screen.queryByTestId('add-button')).not.toBeInTheDocument()
    })

    it('does not show "Add New" button based on addNew being false', () => {
      const newProps = {
        ...props,
        tempEnrollPermissions: {
          ...props.tempEnrollPermissions,
          canAdd: false,
        },
      }

      render(<TempEnrollEdit {...newProps} />)

      expect(screen.queryByTestId('add-button')).not.toBeInTheDocument()
    })
  })

  describe('buttons', () => {
    describe('edit', () => {
      it('calls onEdit with correct enrollment data when clicked', () => {
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('edit-button'))
        expect(props.onEdit).toHaveBeenCalledWith(props.enrollments[0].user, props.enrollments)
      })
    })

    describe('delete', () => {
      beforeEach(() => {
        window.confirm = jest.fn(() => true)
      })

      it('opens a confirmation dialog when delete button is clicked', () => {
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('delete-button'))
        expect(window.confirm).toHaveBeenCalled()
      })

      it('does not perform deletion if user cancels confirmation', async () => {
        window.confirm = jest.fn(() => false)
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('delete-button'))
        await waitFor(() => {
          expect(props.onDelete).not.toHaveBeenCalled()
        })
      })

      it('calls onDelete with correct enrollment IDs on confirm', async () => {
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('delete-button'))
        const allEnrollmentIds = props.enrollments.map((enrollment: Enrollment) => enrollment.id)
        await waitFor(() => {
          expect(props.onDelete).toHaveBeenCalledWith(allEnrollmentIds)
        })
      })
    })

    describe('add new', () => {
      it('calls onAddNew when clicked', () => {
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('add-button'))

        expect(props.onAddNew).toHaveBeenCalled()
      })
    })
  })

  describe('utility functions', () => {
    const mockProviderUser: User = {
      id: '1',
      name: 'Provider User',
    }
    const mockRecipientUser: User = {
      id: '2',
      name: 'Recipient User',
    }
    const mockTempEnrollment: Enrollment = {
      course_id: '0',
      end_at: '',
      id: '0',
      role_id: '',
      start_at: '',
      enrollment_state: '',
      temporary_enrollment_source_user_id: 0,
      type: '',
      limit_privileges_to_course_section: false,
      user: mockRecipientUser,
      temporary_enrollment_provider: mockProviderUser,
      temporary_enrollment_pairing_id: 1,
    }

    describe('getRelevantUserFromEnrollment', () => {
      it('returns temporary_enrollment_provider when present', () => {
        const enrollmentUser: User = getRelevantUserFromEnrollment(mockTempEnrollment)
        expect(enrollmentUser).toBe(mockTempEnrollment.temporary_enrollment_provider)
      })

      it('returns user when temporary_enrollment_provider is absent', () => {
        const tempEnrollment: Enrollment = {
          ...mockTempEnrollment,
          temporary_enrollment_provider: undefined,
        }
        const enrollmentUser = getRelevantUserFromEnrollment(tempEnrollment)
        expect(enrollmentUser).toBe(tempEnrollment.user)
      })
    })

    describe('getEnrollmentUserDisplayName', () => {
      it('returns the name of the relevant user', () => {
        const displayName = getEnrollmentUserDisplayName(mockTempEnrollment)
        expect(displayName).toBe(mockTempEnrollment.temporary_enrollment_provider!.name)
      })
    })

    describe('groupEnrollmentsByPairingId', () => {
      it('groups enrollments by temporary_enrollment_pairing_id', () => {
        const tempEnrollment2: Enrollment = {
          ...mockTempEnrollment,
          temporary_enrollment_pairing_id: 2,
        }
        const tempEnrollment3: Enrollment = {
          ...mockTempEnrollment,
          temporary_enrollment_pairing_id: 2,
        }
        const tempEnrollments = [mockTempEnrollment, tempEnrollment2, tempEnrollment3]
        const grouped = groupEnrollmentsByPairingId(tempEnrollments)
        expect(Object.keys(grouped)).toHaveLength(2)
        expect(grouped[1]).toHaveLength(1)
        expect(grouped[1][0]).toBe(tempEnrollments[0])
        expect(grouped[2]).toHaveLength(2)
        expect(grouped[2][0]).toBe(tempEnrollments[1])
        expect(grouped[2][1]).toBe(tempEnrollments[2])
      })
    })
  })
})

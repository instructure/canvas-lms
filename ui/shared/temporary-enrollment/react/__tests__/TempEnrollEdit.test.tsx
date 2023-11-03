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

import {TempEnrollEdit} from '../TempEnrollEdit'
import React from 'react'
import {fireEvent, render, screen} from '@testing-library/react'
import {PROVIDER, RECIPIENT} from '../types'

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
      ],
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

        expect(props.onEdit).toHaveBeenCalledWith(props.enrollments[0].user) // must be user object
      })
    })

    describe('delete', () => {
      it('opens a confirmation dialog when clicked', async () => {
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('delete-button'))

        expect(window.confirm).toHaveBeenCalled()
      })

      it('calls onDelete with correct enrollment ID on confirm', () => {
        render(<TempEnrollEdit {...props} />)
        fireEvent.click(screen.getByTestId('delete-button'))

        expect(props.onDelete).toHaveBeenCalledWith(props.enrollments[0].id)
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
})

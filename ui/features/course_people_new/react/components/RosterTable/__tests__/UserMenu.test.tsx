/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import UserMenu, {type UserMenuProps} from '../UserMenu'
import {
  OBSERVER_ENROLLMENT,
  INACTIVE_ENROLLMENT
} from '../../../../util/constants'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'
import type {CoursePeopleContextType} from '../../../../types'
import {mockEnrollment} from '../../../../graphql/Mocks'

jest.mock('../../../hooks/useCoursePeopleContext')

const defaultProps: UserMenuProps = {
  uid: '1',
  name: 'John Doe',
  htmlUrl: '/users/1',
  canManage: true,
  canRemoveUsers: true,
  customLinks: [],
  enrollments: [mockEnrollment()],
  onResendInvitation: jest.fn(),
  onLinkStudents: jest.fn(),
  onEditSections: jest.fn(),
  onEditRoles: jest.fn(),
  onReactivateUser: jest.fn(),
  onDeactivateUser: jest.fn(),
  onRemoveUser: jest.fn(),
  onCustomLinkSelect: jest.fn()
}

const defaultContext: Partial<CoursePeopleContextType> = {
  activeGranularEnrollmentPermissions: ['StudentEnrollment'],
  courseConcluded: false
}

const customLinks = [
  {_id: '1', url: '/custom/1', text: 'Custom Link 1', icon_class: 'icon-custom-1'},
  {_id: '2', url: '/custom/2', text: 'Custom Link 2', icon_class: 'icon-custom-2'}
]

const menuButton = `options-menu-user-${defaultProps.uid}`
const resendInvitation = `resend-invitation-user-${defaultProps.uid}`
const editSections = `edit-sections-user-${defaultProps.uid}`
const editRoles = `edit-roles-user-${defaultProps.uid}`
const linkStudents = `link-to-students-user-${defaultProps.uid}`
const detailsUser = `details-user-${defaultProps.uid}`
const deactivateUser = `deactivate-user-${defaultProps.uid}`
const reactivateUser = `reactivate-user-${defaultProps.uid}`
const removeUser = `remove-from-course-user-${defaultProps.uid}`
const customLink1 = `custom-link-${customLinks[0]._id}-user-${defaultProps.uid}`
const customLink2 = `custom-link-${customLinks[1]._id}-user-${defaultProps.uid}`

const renderUserMenu = (props: Partial<UserMenuProps> = {}) => {
  return render(<UserMenu {...defaultProps} {...props} />)
}

describe('UserMenu', () => {
  beforeEach(() => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue(defaultContext)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders menu', () => {
    const {getByTestId} = renderUserMenu()
    expect(getByTestId(menuButton)).toBeInTheDocument()
  })

  it('shows menu items when clicked', () => {
    const {getByTestId, queryByTestId} = renderUserMenu()
    fireEvent.click(getByTestId(menuButton))

    expect(getByTestId(resendInvitation)).toBeInTheDocument()
    expect(getByTestId(editSections)).toBeInTheDocument()
    expect(getByTestId(editRoles)).toBeInTheDocument()
    expect(getByTestId(detailsUser)).toBeInTheDocument()
    expect(getByTestId(deactivateUser)).toBeInTheDocument()
    expect(getByTestId(removeUser)).toBeInTheDocument()
    expect(queryByTestId(reactivateUser)).not.toBeInTheDocument()
  })

  describe('Menu Items Visibility', () => {
    it('shows reactivate user for inactive enrollments', () => {
      const props = {enrollments: [mockEnrollment({
        enrollmentState: INACTIVE_ENROLLMENT
      })]}
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(getByTestId(reactivateUser)).toBeInTheDocument()
      expect(queryByTestId(deactivateUser)).not.toBeInTheDocument()
    })

    it('shows link students for observers', () => {
      const props = {enrollments: [mockEnrollment({
        enrollmentType: OBSERVER_ENROLLMENT
      })]}
      const {getByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(getByTestId(linkStudents)).toBeInTheDocument()
    })

    it('shows resend invitation based on active granular enrollment permissions', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContext,
        activeGranularEnrollmentPermissions: ['TeacherEnrollment']
      })
      const {getByTestId, queryByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(resendInvitation)).not.toBeInTheDocument()
    })

    it('hides resend invitation for inactive enrollments', () => {
      const props = {enrollments: [mockEnrollment({
        enrollmentState: INACTIVE_ENROLLMENT
      })]}
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(resendInvitation)).not.toBeInTheDocument()
    })

    it('hides edit roles and link students when course is concluded', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContext,
        courseConcluded: true
      })
      const {getByTestId, queryByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(linkStudents)).not.toBeInTheDocument()
      expect(queryByTestId(editRoles)).not.toBeInTheDocument()
    })

    it('hides edit roles when canRemoveUsers is false', () => {
      const props = {canRemoveUsers: false}
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(editRoles)).not.toBeInTheDocument()
    })

    it('hides edit roles for observers with linked students', () => {
      const props = {enrollments: [mockEnrollment({
        enrollmentType: OBSERVER_ENROLLMENT,
        hasAssociatedUser: true
      })]}
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(editRoles)).not.toBeInTheDocument()
    })

    it('hides edit sections for inactive enrollments', () => {
      const props = {enrollments: [mockEnrollment({
        enrollmentState: INACTIVE_ENROLLMENT,
      })]}
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(editSections)).not.toBeInTheDocument()
    })

    it('hides edit sections if no editable enrollments', () => {
      const props = {enrollments: [mockEnrollment({
        enrollmentType: OBSERVER_ENROLLMENT})]
      }
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(editSections)).not.toBeInTheDocument()
    })

    it('hides reactivate option when canRemoveUsers is false', () => {
      const props = {
        canRemoveUsers: false,
        enrollments: [mockEnrollment({
          enrollmentState: INACTIVE_ENROLLMENT
        })]
      }
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(reactivateUser)).not.toBeInTheDocument()
      expect(queryByTestId(deactivateUser)).not.toBeInTheDocument()
    })

    it('hides resend invigation, edit sections, edit roles and link student when canManage is false', () => {
      const props = {
        canManage: false,
        enrollments: [mockEnrollment({
          enrollmentType: OBSERVER_ENROLLMENT
        })]
      }
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(resendInvitation)).not.toBeInTheDocument()
      expect(queryByTestId(editSections)).not.toBeInTheDocument()
      expect(queryByTestId(editRoles)).not.toBeInTheDocument()
      expect(queryByTestId(linkStudents)).not.toBeInTheDocument()
    })

    it('hides deactivate user and remove user when canRemoveUsers is false', () => {
      const props = {canRemoveUsers: false}
      const {getByTestId, queryByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))

      expect(queryByTestId(deactivateUser)).not.toBeInTheDocument()
      expect(queryByTestId(reactivateUser)).not.toBeInTheDocument()
      expect(queryByTestId(removeUser)).not.toBeInTheDocument()
    })
  })

  describe('Menu Item Handlers', () => {
    it('calls onResendInvitation handler when resend invitation is clicked', () => {
      const {getByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(resendInvitation))

      expect(defaultProps.onResendInvitation).toHaveBeenCalled()
    })

    it('calls onLinkStudents handler when link to students is clicked', () => {
      const props = {
        enrollments: [mockEnrollment({
          enrollmentType: OBSERVER_ENROLLMENT
        })]
      }
      const {getByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(linkStudents))

      expect(defaultProps.onLinkStudents).toHaveBeenCalled()
    })

    it('calls onEditSections handler when edit sections is clicked', () => {
      const {getByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(editSections))

      expect(defaultProps.onEditSections).toHaveBeenCalled()
    })

    it('calls onEditRoles handler when edit roles is clicked', () => {
      const {getByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(editRoles))

      expect(defaultProps.onEditRoles).toHaveBeenCalled()
    })

    it('calls onReactivateUser handler when reactivate user is clicked', () => {
      const props = {
        enrollments: [mockEnrollment({
          enrollmentState: INACTIVE_ENROLLMENT
        })]
      }
      const {getByTestId} = renderUserMenu(props)
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(reactivateUser))

      expect(defaultProps.onReactivateUser).toHaveBeenCalled()
    })

    it('calls onDeactivateUser handler when deactivate user is clicked', () => {
      const {getByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(deactivateUser))

      expect(defaultProps.onDeactivateUser).toHaveBeenCalled()
    })

    it('calls onRemoveUser handler when remove from course is clicked', () => {
      const {getByTestId} = renderUserMenu()
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(removeUser))

      expect(defaultProps.onRemoveUser).toHaveBeenCalled()
    })

    it('calls onCustomLinkSelect handler when a custom link is clicked', () => {
      const {getByTestId} = renderUserMenu({customLinks})
      fireEvent.click(getByTestId(menuButton))
      fireEvent.click(getByTestId(customLink1))

      expect(defaultProps.onCustomLinkSelect).toHaveBeenCalled()
    })
  })

  describe('Custom Links', () => {
    it('renders custom links when provided', () => {
      const {getByTestId} = renderUserMenu({customLinks})
      fireEvent.click(getByTestId(menuButton))

      expect(getByTestId(customLink1)).toBeInTheDocument()
      expect(getByTestId(customLink2)).toBeInTheDocument()
    })

    it('renders custom links with correct href and text', () => {
      const {getByTestId} = renderUserMenu({customLinks})
      fireEvent.click(getByTestId(menuButton))
      const link1 = getByTestId(customLink1)
      const link2 = getByTestId(customLink2)

      expect(link1).toHaveAttribute('href', '/custom/1')
      expect(link2).toHaveAttribute('href', '/custom/2')
      expect(link1).toHaveTextContent('Custom Link 1')
      expect(link2).toHaveTextContent('Custom Link 2')
    })
  })
})

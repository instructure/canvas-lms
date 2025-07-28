/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {Provider} from 'react-redux'
import $ from 'jquery'

import PermissionsTable from '../PermissionsTable'
import {ROLES, PERMISSIONS} from '../../__tests__/examples'
import createStore from '../../store'

// Mock jQuery screenReaderFlashMessage
jest.mock('jquery', () => ({
  screenReaderFlashMessage: jest.fn(),
}))

// Mock the rails flash notifications
jest.mock('@canvas/rails-flash-notifications', () => ({}))

function renderWithRedux(component, initialState) {
  const store = createStore(initialState)
  return render(<Provider store={store}>{component}</Provider>)
}

const defaultProps = () => ({
  roles: ROLES.filter(r => r.displayed),
  permissions: PERMISSIONS.filter(p => p.displayed),
  setAndOpenRoleTray: jest.fn(),
  setAndOpenPermissionTray: jest.fn(),
})

const defaultInitialState = () => ({
  roles: ROLES,
  permissions: PERMISSIONS,
  apiBusy: [],
  selectedRoles: [],
  activeRoleTray: null,
  activeAddTray: null,
  activePermissionTray: null,
  contextId: '',
  nextFocus: {permissionName: null, roleId: null, targetArea: null},
})

const createStateWithGranulars = () => ({
  ...defaultInitialState(),
  permissions: [permissionWithGranulars, ...PERMISSIONS],
  roles: ROLES.map(role => ({
    ...role,
    permissions: {
      ...role.permissions,
      manage_grades: {
        enabled: 2,
        explicit: true,
        locked: false,
        readonly: false,
        applies_to_descendants: true,
        applies_to_self: true,
      },
      view_all_grades: {
        enabled: 2,
        explicit: true,
        locked: false,
        readonly: false,
        applies_to_descendants: true,
        applies_to_self: true,
      },
      edit_grades: {
        enabled: 2,
        explicit: true,
        locked: false,
        readonly: false,
        applies_to_descendants: true,
        applies_to_self: true,
      },
    },
  })),
})

// Mock permission with granular permissions for testing expand/collapse
const permissionWithGranulars = {
  permission_name: 'manage_grades',
  label: 'Manage Grades',
  contextType: 'Course',
  displayed: true,
  granular_permissions: [
    {
      permission_name: 'view_all_grades',
      label: 'View All Grades',
      granular_permission_group: 'manage_grades',
      contextType: 'Course',
      displayed: true,
    },
    {
      permission_name: 'edit_grades',
      label: 'Edit Grades',
      granular_permission_group: 'manage_grades',
      contextType: 'Course',
      displayed: true,
    },
  ],
}

describe('PermissionsTable', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Component Structure', () => {
    it('renders the permissions table with correct structure', () => {
      renderWithRedux(<PermissionsTable {...defaultProps()} />, defaultInitialState())

      expect(screen.getByRole('table')).toBeInTheDocument()
      expect(screen.getByText('Permissions')).toBeInTheDocument()
    })

    it('renders all displayed roles in the header', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.roles.forEach(role => {
        expect(screen.getByText(role.label)).toBeInTheDocument()
      })
    })

    it('renders all displayed permissions in the left column', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.permissions.forEach(permission => {
        expect(screen.getByText(permission.label)).toBeInTheDocument()
      })
    })

    it('creates permission buttons for each role-permission combination', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      // Check that we have the expected number of permission buttons
      // Each displayed permission should have a button for each displayed role
      const displayedPermissions = props.permissions.length
      const displayedRoles = props.roles.length
      const expectedButtons = displayedPermissions * displayedRoles

      // Permission buttons don't have a specific role, so we check by class or test id
      const permissionCells = screen
        .getAllByRole('cell')
        .filter(cell => cell.querySelector('.ic-permissions__cell-content'))
      expect(permissionCells).toHaveLength(expectedButtons)
    })
  })

  describe('Role Header Interactions', () => {
    it('calls setAndOpenRoleTray when role header is clicked', async () => {
      const props = defaultProps()
      const user = userEvent.setup()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      const firstRole = props.roles[0]
      const roleLink = screen.getByRole('button', {name: firstRole.label})

      await user.click(roleLink)

      expect(props.setAndOpenRoleTray).toHaveBeenCalledWith(firstRole)
    })

    it('creates proper IDs for role headers', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.roles.forEach(role => {
        const roleButton = screen.getByRole('button', {name: role.label})
        expect(roleButton).toHaveAttribute('id', `role_${role.id}`)
      })
    })
  })

  describe('Permission Header Interactions', () => {
    it('calls setAndOpenPermissionTray when permission header is clicked', async () => {
      const props = defaultProps()
      const user = userEvent.setup()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      const firstPermission = props.permissions[0]
      const permissionLink = screen.getByRole('button', {name: firstPermission.label})

      await user.click(permissionLink)

      expect(props.setAndOpenPermissionTray).toHaveBeenCalledWith(firstPermission)
    })

    it('creates proper IDs for permission headers', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.permissions.forEach(permission => {
        const permissionButton = screen.getByRole('button', {name: permission.label})
        expect(permissionButton).toHaveAttribute('id', `permission_${permission.permission_name}`)
      })
    })
  })

  describe('Granular Permissions', () => {
    it('does not show expand button for permissions without granular permissions', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, createStateWithGranulars())

      const firstPermission = props.permissions[0]
      const expandButton = screen.queryByTestId(`expand_${firstPermission.permission_name}`)
      expect(expandButton).not.toBeInTheDocument()
    })
  })

  describe('Table Cell Structure', () => {
    it('creates proper cell IDs for role-permission combinations', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.permissions.forEach(permission => {
        props.roles.forEach(role => {
          const cellId = `${permission.permission_name}_role_${role.id}`
          const cell = document.getElementById(cellId)
          expect(cell).toBeInTheDocument()
        })
      })
    })

    it('applies correct CSS classes to table elements', () => {
      renderWithRedux(<PermissionsTable {...defaultProps()} />, defaultInitialState())

      expect(document.querySelector('.ic-permissions__table-container')).toBeInTheDocument()
      expect(document.querySelector('.ic-permissions__table')).toBeInTheDocument()
      expect(document.querySelector('.ic-permissions__top-header')).toBeInTheDocument()
      expect(document.querySelector('.ic-permissions__corner-stone')).toBeInTheDocument()
    })
  })

  describe('Accessibility', () => {
    it('has proper table structure with headers', () => {
      renderWithRedux(<PermissionsTable {...defaultProps()} />, defaultInitialState())

      const table = screen.getByRole('table')
      expect(table).toBeInTheDocument()

      // Check for column headers
      expect(screen.getByRole('columnheader', {name: /permissions/i})).toBeInTheDocument()

      // Check for row headers (permissions)
      const props = defaultProps()
      props.permissions.forEach(permission => {
        expect(screen.getByRole('rowheader', {name: permission.label})).toBeInTheDocument()
      })
    })

    it('sets proper ARIA labels on role headers', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.roles.forEach(role => {
        const headerCell = document.querySelector(`[data-role-name="${role.label}"]`)
        expect(headerCell).toBeInTheDocument()
      })
    })

    it('sets proper ARIA labels on permission headers', () => {
      const props = defaultProps()
      renderWithRedux(<PermissionsTable {...props} />, defaultInitialState())

      props.permissions.forEach(permission => {
        const headerCell = screen.getByRole('rowheader', {name: permission.label})
        expect(headerCell).toHaveAttribute('aria-label', permission.label)
      })
    })
  })

  describe('Legacy Tests', () => {
    it('can be imported without errors', () => {
      expect(PermissionsTable).toBeDefined()
      expect(typeof PermissionsTable).toBe('function')
    })

    it('has the expected propTypes structure', () => {
      expect(PermissionsTable.propTypes).toBeDefined()
    })
  })
})

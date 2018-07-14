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

import {getSortedRoles, roleSortedInsert, roleIsCourseBaseRole, roleIsBaseRole} from '../utils'

it('getSortedRoles sorts roles properly based on base_role_type', () => {
  const UNORDERED_ROLES = [
    {
      id: '13',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '1',
      role: 'BASE_TYPE_ONE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '10',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_FOUR'
    },
    {
      id: '2',
      role: 'BASE_TYPE_TWO',
      base_role_type: 'BASE_TYPE_TWO'
    },
    {
      id: '3',
      role: 'BASE_TYPE_THREE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '4',
      role: 'BASE_TYPE_FOUR',
      base_role_type: 'BASE_TYPE_FOUR'
    }
  ]

  const ORDERED_ROLES = [
    {
      id: '1',
      role: 'BASE_TYPE_ONE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '2',
      role: 'BASE_TYPE_TWO',
      base_role_type: 'BASE_TYPE_TWO'
    },
    {
      id: '3',
      role: 'BASE_TYPE_THREE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '13',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '4',
      role: 'BASE_TYPE_FOUR',
      base_role_type: 'BASE_TYPE_FOUR'
    },
    {
      id: '10',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_FOUR'
    }
  ]

  const orderedRoles = getSortedRoles(UNORDERED_ROLES)
  expect(orderedRoles).toMatchObject(ORDERED_ROLES)
})

it('getSortedRoles sorts roles properly for NON_BASE_TYPE at beginning', () => {
  const UNORDERED_ROLES = [
    {
      id: '20',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '13',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '1',
      role: 'BASE_TYPE_ONE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '2',
      role: 'BASE_TYPE_TWO',
      base_role_type: 'BASE_TYPE_TWO'
    },
    {
      id: '3',
      role: 'BASE_TYPE_THREE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '11',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    }
  ]

  const ORDERED_ROLES = [
    {
      id: '1',
      role: 'BASE_TYPE_ONE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '11',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '20',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '2',
      role: 'BASE_TYPE_TWO',
      base_role_type: 'BASE_TYPE_TWO'
    },
    {
      id: '3',
      role: 'BASE_TYPE_THREE',
      base_role_type: 'BASE_TYPE_THREE'
    },
    {
      id: '13',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_THREE'
    }
  ]

  const orderedRoles = getSortedRoles(UNORDERED_ROLES)
  expect(orderedRoles).toMatchObject(ORDERED_ROLES)
})

it('getSortedRoles sorts roles properly for NON_BASE_TYPE in middle and seperated', () => {
  const UNORDERED_ROLES = [
    {
      id: '1',
      role: 'BASE_TYPE_ONE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '11',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '2',
      role: 'BASE_TYPE_TWO',
      base_role_type: 'BASE_TYPE_TWO'
    },
    {
      id: '20',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '3',
      role: 'BASE_TYPE_THREE',
      base_role_type: 'BASE_TYPE_THREE'
    }
  ]

  const ORDERED_ROLES = [
    {
      id: '1',
      role: 'BASE_TYPE_ONE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '11',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '20',
      role: 'NON_BASE_TYPE',
      base_role_type: 'BASE_TYPE_ONE'
    },
    {
      id: '2',
      role: 'BASE_TYPE_TWO',
      base_role_type: 'BASE_TYPE_TWO'
    },
    {
      id: '3',
      role: 'BASE_TYPE_THREE',
      base_role_type: 'BASE_TYPE_THREE'
    }
  ]

  const orderedRoles = getSortedRoles(UNORDERED_ROLES)
  expect(orderedRoles).toMatchObject(ORDERED_ROLES)
})

const ALL_ROLES = [
  {
    id: '1',
    role: 'BASE_TYPE_ONE',
    base_role_type: 'BASE_TYPE_ONE'
  },
  {
    id: '11',
    role: 'NON_BASE_TYPE',
    base_role_type: 'BASE_TYPE_ONE'
  },
  {
    id: '2',
    role: 'BASE_TYPE_TWO',
    base_role_type: 'BASE_TYPE_TWO'
  },
  {
    id: '3',
    role: 'BASE_TYPE_THREE',
    base_role_type: 'BASE_TYPE_THREE'
  }
]

it('roleSortedInsert sorts roles properly inserts Role into first item', () => {
  const ROLE_TO_INSERT = {
    id: '20',
    role: 'NON_BASE_TYPE',
    base_role_type: 'BASE_TYPE_ONE'
  }

  const ORDERED_ROLES = ALL_ROLES.slice()
  ORDERED_ROLES.splice(2, 0, ROLE_TO_INSERT)

  const orderedRoles = roleSortedInsert(ALL_ROLES, ROLE_TO_INSERT)
  expect(orderedRoles).toMatchObject(ORDERED_ROLES)
})

it('roleSortedInsert sorts roles properly inserts Role into last item', () => {
  const ROLE_TO_INSERT = {
    id: '20',
    role: 'NON_BASE_TYPE',
    base_role_type: 'BASE_TYPE_THREE'
  }

  const ORDERED_ROLES = ALL_ROLES.slice()
  ORDERED_ROLES.splice(ALL_ROLES.length, 0, ROLE_TO_INSERT)

  const orderedRoles = roleSortedInsert(ALL_ROLES, ROLE_TO_INSERT)
  expect(orderedRoles).toMatchObject(ORDERED_ROLES)
})

it('roleSortedInsert sorts roles properly inserts Role into middle item', () => {
  const ROLE_TO_INSERT = {
    id: '20',
    role: 'NON_BASE_TYPE',
    base_role_type: 'BASE_TYPE_TWO'
  }

  const ORDERED_ROLES = ALL_ROLES.slice()
  ORDERED_ROLES.splice(3, 0, ROLE_TO_INSERT)

  const orderedRoles = roleSortedInsert(ALL_ROLES, ROLE_TO_INSERT)
  expect(orderedRoles).toMatchObject(ORDERED_ROLES)
})

it('does not return account base roles as course base roles', () => {
  const accountBaserole = {
    id: '1',
    role: 'AccountAdmin',
    base_role_type: 'AccountMembership'
  }

  expect(roleIsCourseBaseRole(accountBaserole)).toBeFalsy()
  expect(roleIsBaseRole(accountBaserole)).toBeTruthy()
})

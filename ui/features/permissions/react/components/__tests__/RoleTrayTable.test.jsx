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
import {render} from '@testing-library/react'

import {ROLES} from '../../__tests__/examples'
import RoleTrayTable from '../RoleTrayTable'
import RoleTrayTableRow from '../RoleTrayTableRow'

function createRowProps(title, roleId) {
  const role = ROLES.find(r => r.id === roleId)
  const permissionName = Object.keys(role.permissions)[0]
  const permission = role.permissions[permissionName]
  const onChange = Function.prototype

  return {
    title,
    role,
    permission,
    permissionName,
    permissionLabel: 'whatever',
    onChange,
    permButton: () => <div>Mock Button</div>,
    permCheckbox: () => <div>Mock Checkbox</div>,
  }
}

it('renders the component with only one child', () => {
  const {container} = render(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow {...createRowProps('banana', '1')} />
    </RoleTrayTable>,
  )
  // RoleTrayTable wraps each child in a span, so count those
  const wrappers = container.querySelectorAll('.ic-permissions_role_tray > span')
  expect(wrappers).toHaveLength(1)
})

it('renders the component with multiple children', () => {
  const {container} = render(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow {...createRowProps('banana', '1')} />
      <RoleTrayTableRow {...createRowProps('apple', '2')} />
      <RoleTrayTableRow {...createRowProps('mango', '3')} />
    </RoleTrayTable>,
  )
  const wrappers = container.querySelectorAll('.ic-permissions_role_tray > span')
  expect(wrappers).toHaveLength(3)
})

it('renders the title', () => {
  const {getByRole} = render(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow {...createRowProps('banana', '1')} />
    </RoleTrayTable>,
  )
  const heading = getByRole('heading', {level: 3})
  expect(heading).toHaveTextContent('fruit')
})

it('sorts the children by title', () => {
  const {getByText} = render(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow {...createRowProps('banana', '1')} />
      <RoleTrayTableRow {...createRowProps('apple', '2')} />
      <RoleTrayTableRow {...createRowProps('mango', '3')} />
    </RoleTrayTable>,
  )

  // Check that the rows are rendered in sorted order
  const apple = getByText('apple')
  const banana = getByText('banana')
  const mango = getByText('mango')

  // Use compareDocumentPosition to check DOM order
  // If apple comes before banana, the result should include DOCUMENT_POSITION_FOLLOWING (4)
  expect(apple.compareDocumentPosition(banana) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  expect(banana.compareDocumentPosition(mango) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
})

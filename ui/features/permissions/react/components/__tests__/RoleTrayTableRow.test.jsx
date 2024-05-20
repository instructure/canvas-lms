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
import RoleTrayTableRow from '../RoleTrayTableRow'

const MockedButton = () => <div className="mocked-permissionbutton" />
const MockedCheckbox = () => <input type="checkbox" className="mocked-permissioncheckbox" />
const defaultProps = (title, roleId) => {
  const role = ROLES.find(r => r.id === roleId)
  const permissionName = Object.keys(role.permissions)[0]
  const permission = role.permissions[permissionName]
  const permissionLabel = 'whatever'
  const onChange = Function.prototype
  const permButton = MockedButton
  const permCheckbox = MockedCheckbox

  permission.permissionLabel = 'test'

  return {
    title,
    role,
    permission,
    permissionName,
    permissionLabel,
    onChange,
    permButton,
    permCheckbox,
  }
}
const renderRoleTrayTableRow = settings => {
  const baseProps = defaultProps(settings.title, settings.roleId)
  const props = {
    ...baseProps,
    ...settings.props,
    permission: {
      ...baseProps.permission,
      ...settings.props?.permission,
    },
  }

  return render(<RoleTrayTableRow {...props} />)
}

describe('RoleTrayTableRow', () => {
  it('renders the title', () => {
    const {getByText} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
    })

    expect(getByText('banana')).toBeInTheDocument()
  })

  it('renders the expandable button if expandable prop is true', () => {
    const {container} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
      props: {
        expandable: true,
      },
    })
    const node = container.querySelector('.ic-permissions_role_tray_table_role_expandable')

    expect(node).toBeInTheDocument()
  })

  it('does not render the expandable button if expandable prop is false', () => {
    const {container} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
      props: {
        expandable: false,
      },
    })
    const node = container.querySelector('.ic-permissions_role_tray_table_role_expandable')

    expect(node).not.toBeInTheDocument()
  })

  it('renders the description if provided', () => {
    const {getByText, container} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
      props: {
        description: "it's a fruit",
      },
    })
    const allSpans = container.querySelectorAll('span[direction="column"] > span')
    const node1 = getByText("it's a fruit")
    const node2 = getByText('banana')

    expect(allSpans.length).toEqual(2)
    expect(node1).toBeInTheDocument()
    expect(node2).toBeInTheDocument()
  })

  it('does not render the description if not provided', () => {
    const {queryByText, container} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
      props: {
        description: '',
      },
    })
    const node = queryByText('banana')
    const allSpans = container.querySelectorAll('span[direction="column"] > span')
    const emptySpan = allSpans[1]

    expect(emptySpan.children).toHaveLength(0)
    expect(node).toBeInTheDocument()
  })

  it('renders a Permission Button for a "regular old" permission', () => {
    const {container} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
    })
    const node = container.querySelector('.mocked-permissionbutton')

    expect(node).toBeInTheDocument()
  })

  it('renders a checkbox for a granular permission', () => {
    const {container, debug} = renderRoleTrayTableRow({
      title: 'banana',
      roleId: '1',
      props: {
        permission: {
          group: 'group-permission-name',
        },
      },
    })
    debug()
    const node = container.querySelector('input.mocked-permissioncheckbox')

    expect(node).toBeInTheDocument()
  })
})

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import sinon from 'sinon'
import userEvent from '@testing-library/user-event'
import MigrationSync from '../MigrationSync'

describe('MigrationSync component', () => {
  const defaultProps = () => ({
    migrationStatus: 'void',
    hasCheckedMigration: true,
    isLoadingBeginMigration: false,
    checkMigration: () => {},
    beginMigration: () => {},
    stopMigrationStatusPoll: () => {},
  })

  test('renders the MigrationSync component', () => {
    const tree = shallow(<MigrationSync {...defaultProps()} />)
    const node = tree.find('.bcs__migration-sync')
    expect(node).toBeTruthy()
  })

  test('renders the progress indicator if in a loading migration state', () => {
    const props = defaultProps()
    props.migrationStatus = 'queued'
    const tree = shallow(<MigrationSync {...props} />)
    const node = tree.find('.bcs__migration-sync__loading')
    expect(node).toBeTruthy()
  })

  test('renders the progress indicator if in the process of beginning a migration', () => {
    const props = defaultProps()
    props.isLoadingBeginMigration = true
    const tree = shallow(<MigrationSync {...props} />)
    const node = tree.find('.bcs__migration-sync__loading')
    expect(node).toBeTruthy()
  })

  test('calls beginMigration when sync button is clicked', async () => {
    const props = defaultProps()
    props.beginMigration = sinon.spy()
    const tree = render(<MigrationSync {...props} />)
    const button = tree.container.querySelector('.bcs__migration-sync button')
    const user = userEvent.setup({delay: null})
    await user.click(button)
    expect(props.beginMigration.callCount).toEqual(1)
  })

  test('calls checkMigration on mount if it has not been checked already', () => {
    const props = defaultProps()
    props.hasCheckedMigration = false
    props.checkMigration = sinon.spy()
    const tree = shallow(<MigrationSync {...props} />)
    expect(props.checkMigration.callCount).toEqual(1)
  })

  test('does not call checkMigration on mount if it has been checked already', () => {
    const props = defaultProps()
    props.hasCheckedMigration = true
    props.checkMigration = sinon.spy()
    const tree = shallow(<MigrationSync {...props} />)
    expect(props.checkMigration.callCount).toEqual(0)
  })
})

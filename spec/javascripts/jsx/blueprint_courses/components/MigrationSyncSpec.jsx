/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import * as enzyme from 'enzyme'
import MigrationSync from 'ui/features/blueprint_course_master/react/components/MigrationSync'

QUnit.module('MigrationSync component')

const defaultProps = () => ({
  migrationStatus: 'void',
  hasCheckedMigration: true,
  isLoadingBeginMigration: false,
  checkMigration: () => {},
  beginMigration: () => {},
  stopMigrationStatusPoll: () => {},
})

test('renders the MigrationSync component', () => {
  const tree = enzyme.shallow(<MigrationSync {...defaultProps()} />)
  const node = tree.find('.bcs__migration-sync')
  ok(node.exists())
})

test('renders the progress indicator if in a loading migration state', () => {
  const props = defaultProps()
  props.migrationStatus = 'queued'
  const tree = enzyme.shallow(<MigrationSync {...props} />)
  const node = tree.find('.bcs__migration-sync__loading')
  ok(node.exists())
})

test('renders the progress indicator if in the process of beginning a migration', () => {
  const props = defaultProps()
  props.isLoadingBeginMigration = true
  const tree = enzyme.shallow(<MigrationSync {...props} />)
  const node = tree.find('.bcs__migration-sync__loading')
  ok(node.exists())
})

test('calls beginMigration when sync button is clicked', () => {
  const props = defaultProps()
  props.beginMigration = sinon.spy()
  const tree = enzyme.mount(<MigrationSync {...props} />)
  const button = tree.find('.bcs__migration-sync button')
  button.at(0).simulate('click')
  equal(props.beginMigration.callCount, 1)
})

test('calls checkMigration on mount if it has not been checked already', () => {
  const props = defaultProps()
  props.hasCheckedMigration = false
  props.checkMigration = sinon.spy()
  const tree = enzyme.shallow(<MigrationSync {...props} />)
  equal(props.checkMigration.callCount, 1)
})

test('does not call checkMigration on mount if it has been checked already', () => {
  const props = defaultProps()
  props.hasCheckedMigration = true
  props.checkMigration = sinon.spy()
  const tree = enzyme.shallow(<MigrationSync {...props} />)
  equal(props.checkMigration.callCount, 0)
})

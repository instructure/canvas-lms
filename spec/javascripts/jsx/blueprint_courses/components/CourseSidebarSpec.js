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
import CourseSidebar from 'jsx/blueprint_courses/components/CourseSidebar'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'
import sampleData from '../sampleData'

const noop = () => {}

const defaultProps = () => ({
  hasLoadedAssociations: false,
  associations: sampleData.courses,
  loadAssociations: noop,
  saveAssociations: noop,
  clearAssociations: noop,
  hasAssociationChanges: true,
  isSavingAssociations: false,
  willSendNotification: false,
  enableSendNotification: noop,
  loadUnsynchedChanges: noop,
  isLoadingUnsynchedChanges: false,
  hasLoadedUnsynchedChanges: true,
  unsynchedChanges: sampleData.unsynchedChanges,
  migrationStatus: MigrationStates.states.unknown,
  isLoadingBeginMigration: false,
})

QUnit.module('Course Sidebar component')

test('renders the CourseSidebar component', () => {
  const tree = enzyme.shallow(<CourseSidebar {...defaultProps()} />)
  const rows = tree.find('.bcs__row')
  equal(rows.length, 4)
})

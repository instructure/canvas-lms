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
import SyncHistory from 'ui/features/blueprint_course_master/react/components/SyncHistory'
import getSampleData from '../getSampleData'

QUnit.module('SyncHistory component')

const defaultProps = () => ({
  loadHistory: () => {},
  isLoadingHistory: false,
  hasLoadedHistory: false,
  loadAssociations: () => {},
  isLoadingAssociations: false,
  hasLoadedAssociations: false,
  migrations: getSampleData().history,
})

test('renders the SyncHistory component', () => {
  const tree = enzyme.shallow(<SyncHistory {...defaultProps()} />)
  const node = tree.find('.bcs__history')
  ok(node.exists())
})

test('displays spinner when loading courses', () => {
  const props = defaultProps()
  props.isLoadingHistory = true
  const tree = enzyme.shallow(<SyncHistory {...props} />)
  const node = tree.find('.bcs__history Spinner')
  ok(node.exists())
})

test('renders SyncHistoryItem components for each migration', () => {
  const tree = enzyme.mount(<SyncHistory {...defaultProps()} />)
  const node = tree.find('SyncHistoryItem')
  equal(node.length, 1)
})

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
import ChildChangeLog from 'ui/features/blueprint_course_child/react/components/ChildChangeLog'
import loadStates from '@canvas/blueprint-courses/react/loadStates'
import getSampleData from '../getSampleData'

QUnit.module('ChildChangeLog component')

const defaultProps = () => ({
  status: loadStates.states.not_loaded,
  migration: getSampleData().history[0],
})

test('renders the ChildChangeLog component', () => {
  const tree = enzyme.shallow(<ChildChangeLog {...defaultProps()} />)
  const node = tree.find('.bcc__change-log')
  ok(node.exists())
})

test('renders loading indicator if in loading state', () => {
  const props = defaultProps()
  props.status = loadStates.states.loading
  const tree = enzyme.shallow(<ChildChangeLog {...props} />)
  const node = tree.find('.bcc__change-log__loading')
  ok(node.exists())
})

test('renders history item when in loaded state', () => {
  const props = defaultProps()
  props.status = loadStates.states.loaded
  const tree = enzyme.shallow(<ChildChangeLog {...props} />)
  const node = tree.find('SyncHistoryItem')
  ok(node.exists())
})

test('does not render history item when in loading state', () => {
  const props = defaultProps()
  props.status = loadStates.states.loading
  const tree = enzyme.shallow(<ChildChangeLog {...props} />)
  const node = tree.find('SyncHistoryItem')
  notOk(node.exists())
})

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
import ExpandableLockOptions from 'jsx/blueprint_courses/components/ExpandableLockOptions'


QUnit.module('ExpandableLockOptions component')

const defaultProps = () => ({
  objectType: 'assignment',
  isOpen: false,
  lockableAttributes: ['content', 'points', 'due_dates', 'availability_dates'],
  locks: {
    content: false,
    points: false,
    due_dates: false,
    availability_dates: false,
  },
})

test('renders the ToggleMenuTab component', () => {
  const tree = enzyme.shallow(<ExpandableLockOptions {...defaultProps()} />)
  const node = tree.find('.bcs__object-tab')
  ok(node.exists())
})

test('renders the closed toggle Icon', () => {
  const tree = enzyme.shallow(<ExpandableLockOptions {...defaultProps()} />)
  const icon = tree.find('.bcs_tab_indicator-icon IconArrowOpenRight')
  equal(icon.length, 1)
})

test('renders the opened toggle Icon', () => {
  const props = defaultProps()
  props.isOpen = true
  const tree = enzyme.shallow(<ExpandableLockOptions {...props} />)
  const icon = tree.find('.bcs_tab_indicator-icon IconArrowOpenDown')
  equal(icon.length, 1)
})

test('opens the submenu when toggle is clicked', (assert) => {
  const done = assert.async()
  const tree = enzyme.mount(<ExpandableLockOptions {...defaultProps()} />)
  const toggle = tree.find('.bcs_tab-icon')
  toggle.at(0).simulate('click')
  setTimeout(() => {
    const submenu = tree.find('LockCheckList')
    ok(submenu.exists())
    done()
  }, 0)
})

test('doesnt render the sub list initially', () => {
  const tree = enzyme.shallow(<ExpandableLockOptions {...defaultProps()} />)
  const list = tree.find('.bcs_check_box-group')
  notOk(list.exists())
})

test('renders the unlocked lock Icon when unlocked', () => {
  const tree = enzyme.shallow(<ExpandableLockOptions {...defaultProps()} />)
  const icon = tree.find('.bcs_tab-icon IconUnlock')
  equal(icon.length, 1)
})

test('renders the locked lock Icon when locked', () => {
  const props = defaultProps()
  props.locks.content = true
  const tree = enzyme.shallow(<ExpandableLockOptions {...props} />)
  const icon = tree.find('.bcs_tab-icon IconLock')
  equal(icon.length, 1)
})

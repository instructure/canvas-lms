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
import { mount } from 'enzyme'
import merge from 'lodash/merge'
import ToggleIcon from 'jsx/shared/components/ToggleIcon'

QUnit.module('ToggleIcon component')

const makeProps = (props = {}) => merge({
  toggled: true,
  OnIcon: <span className="onIcon" />,
  OffIcon: <span className="offIcon" />,
  onToggleOn: () => {},
  onToggleOff: () => {},
  disabled: false,
}, props)

test('renders the ToggleIcon component', () => {
  const tree = mount(<ToggleIcon {...makeProps()} />)
  ok(tree.exists())
})

test('renders the on icon when toggled', () => {
  const tree = mount(<ToggleIcon {...makeProps()} />)
  ok(tree.find('.onIcon').exists())
  ok(!tree.find('.offIcon').exists())
})

test('renders the off icon when untoggled', () => {
  const tree = mount(<ToggleIcon {...makeProps({ toggled: false })} />)
  ok(!tree.find('.onIcon').exists())
  ok(tree.find('.offIcon').exists())
})

test('calls onToggleOff when clicked while toggled', () => {
  const onToggleOn = sinon.spy()
  const onToggleOff = sinon.spy()
  const tree = mount(<ToggleIcon {...makeProps({ onToggleOn, onToggleOff })} />)

  tree.find('.onIcon').simulate('click')
  strictEqual(onToggleOff.callCount, 1)
  strictEqual(onToggleOn.callCount, 0)
})

test('calls onToggleOn when clicked while untoggled', () => {
  const onToggleOn = sinon.spy()
  const onToggleOff = sinon.spy()
  const tree = mount(<ToggleIcon {...makeProps({ onToggleOn, onToggleOff, toggled: false })} />)

  tree.find('.offIcon').simulate('click')
  strictEqual(onToggleOff.callCount, 0)
  strictEqual(onToggleOn.callCount, 1)
})

test('cannot be clicked if disabled', () => {
  const onToggleOn = sinon.spy()
  const onToggleOff = sinon.spy()
  const tree = mount(<ToggleIcon {...makeProps({ onToggleOn, onToggleOff, disabled: true })} />)

  tree.find('.onIcon').simulate('click')
  strictEqual(onToggleOff.callCount, 0)
  strictEqual(onToggleOn.callCount, 0)
})

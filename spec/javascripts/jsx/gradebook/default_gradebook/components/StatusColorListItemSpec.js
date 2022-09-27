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
import {shallow} from 'enzyme'
import {Text} from '@instructure/ui-text'
import StatusColorListItem from 'ui/features/gradebook/react/default_gradebook/components/StatusColorListItem'

function defaultProps(props = {}) {
  return {
    status: 'late',
    color: '#efefef',
    isColorPickerShown: false,
    colorPickerOnToggle() {},
    colorPickerButtonRef() {},
    colorPickerContentRef() {},
    colorPickerAfterClose() {},
    afterSetColor() {},
    ...props,
  }
}

QUnit.module('StatusColorListItem', {
  setup() {
    this.wrapper = shallow(<StatusColorListItem {...defaultProps()} />)
    this.instance = this.wrapper.instance()
  },

  teardown() {
    this.wrapper.unmount()
  },
})

test('color is passed to ColorPicker', function () {
  strictEqual(this.wrapper.find('ColorPicker').prop('currentColor'), this.instance.props.color)
})

test('parentCompontent is StatusColorListItem', function () {
  strictEqual(this.wrapper.find('ColorPicker').prop('parentComponent'), 'StatusColorListItem')
})

test('status is displayed', function () {
  ok(this.wrapper.contains(<Text>Late</Text>))
})

test('popover trigger is an edit icon', function () {
  const iconInside = this.wrapper.find('Popover').prop('renderTrigger').props.children
    .type.displayName
  strictEqual(iconInside, 'IconEditSolid')
})

test('setColor sets the ColorPicker color', function () {
  const color = '#FFFFFF'
  this.instance.setColor(color)
  strictEqual(this.wrapper.find('ColorPicker').prop('currentColor'), color)
})

test('setColor sets the ColorPicker color, even with no octothorpe', function () {
  const color = 'FFFFFF'
  this.instance.setColor(color)
  strictEqual(this.wrapper.find('ColorPicker').prop('currentColor'), `#${color}`)
})

test('setColor sets li style', function () {
  const color = '#FFFFFF'
  this.instance.setColor(color)
  strictEqual(this.wrapper.find('li').prop('style').backgroundColor, color)
})

test('setColor sets li style, even with no octothorpe', function () {
  const color = 'FFFFFF'
  this.instance.setColor(color)
  strictEqual(this.wrapper.find('li').prop('style').backgroundColor, `#${color}`)
})

QUnit.module('StatusColorListItem afterSetColor')

test('setColor calls afterSetColor', () => {
  const afterSetColor = sinon.stub()
  const wrapper = shallow(<StatusColorListItem {...defaultProps({afterSetColor})} />)
  const instance = wrapper.instance()
  instance.setColor('#FFFFFF')
  strictEqual(afterSetColor.callCount, 1)
  wrapper.unmount()
})

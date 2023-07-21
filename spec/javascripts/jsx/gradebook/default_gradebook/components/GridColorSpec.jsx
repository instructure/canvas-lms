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
import {mount, shallow} from 'enzyme'
import GridColor from 'ui/features/gradebook/react/default_gradebook/components/GridColor'
import {
  darken,
  defaultColors,
  statusColors,
} from 'ui/features/gradebook/react/default_gradebook/constants/colors'

function defaultProps(props = {}) {
  return {
    colors: statusColors(),
    ...props,
  }
}

QUnit.module('GridColor', {
  setup() {
    this.wrapper = shallow(<GridColor colors={{}} />)
  },
  teardown() {
    this.wrapper.unmount()
  },
})

test('it renders style', function () {
  strictEqual(this.wrapper.find('style[type="text/css"]').length, 1)
})

QUnit.module('GridColor rendered html', {
  setup() {
    this.wrapper = mount(<GridColor {...defaultProps()} />)
  },
  teardown() {
    this.wrapper.unmount()
  },
})

test('it has blue as a default color', function () {
  ok(this.wrapper.html().includes(defaultColors.blue))
})

test('it has salmon as a default color', function () {
  ok(this.wrapper.html().includes(defaultColors.salmon))
})

test('it has green as a default color', function () {
  ok(this.wrapper.html().includes(defaultColors.green))
})

test('it has orange as a default color', function () {
  ok(this.wrapper.html().includes(defaultColors.orange))
})

test('it has yellow as a default color', function () {
  ok(this.wrapper.html().includes(defaultColors.yellow))
})

test('it has darker blue as a default color', function () {
  const color = darken(defaultColors.blue, 5)
  ok(this.wrapper.html().includes(color))
})

test('it has dark salmon as a default color', function () {
  const color = darken(defaultColors.salmon, 5)
  ok(this.wrapper.html().includes(color))
})

test('it has dark green as a default color', function () {
  const color = darken(defaultColors.green, 5)
  ok(this.wrapper.html().includes(color))
})

test('it has dark orange as a default color', function () {
  const color = darken(defaultColors.orange, 5)
  ok(this.wrapper.html().includes(color))
})

test('it has dark yellow as a default color', function () {
  const color = darken(defaultColors.yellow, 5)
  ok(this.wrapper.html().includes(color))
})

QUnit.module('GridColor css rules')

test('rules are for .gradebook-cell and .`statuses`', () => {
  const props = defaultProps({statuses: ['late']})
  const wrapper = mount(<GridColor {...props} />)
  equal(
    wrapper.html(),
    '<style type="text/css" data-testid="grid-color">' +
      `.even .gradebook-cell.late { background-color: ${defaultColors.blue}; }` +
      `.odd .gradebook-cell.late { background-color: ${darken(defaultColors.blue, 5)}; }` +
      '.slick-cell.editable .gradebook-cell.late { background-color: white; }' +
      '</style>'
  )
  wrapper.unmount()
})

test('multiple state rules are concatenated', () => {
  const props = defaultProps({statuses: ['late', 'missing']})
  const wrapper = shallow(<GridColor {...props} />)
  const expected = (
    <style type="text/css" data-testid="grid-color">
      {`.even .gradebook-cell.late { background-color: ${defaultColors.blue}; }` +
        `.odd .gradebook-cell.late { background-color: ${darken(defaultColors.blue, 5)}; }` +
        '.slick-cell.editable .gradebook-cell.late { background-color: white; }' +
        `.even .gradebook-cell.missing { background-color: ${defaultColors.salmon}; }` +
        `.odd .gradebook-cell.missing { background-color: ${darken(defaultColors.salmon, 5)}; }` +
        '.slick-cell.editable .gradebook-cell.missing { background-color: white; }'}
    </style>
  )
  ok(wrapper.equals(expected))
  wrapper.unmount()
})

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

 /* global expect */
import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import { mount, shallow } from 'enzyme'
import SectionTooltip from '../SectionsTooltip'

const defaultProps = () => ({
  sections: [{id: 2, name: 'sections name', user_count: 4}],
  totalUserCount: 5,
})

test('renders the SectionTooltip component', () => {
  const tree = mount(<SectionTooltip {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('renders the correct section text', () => {
  const tree = mount(<SectionTooltip {...defaultProps()} />)
  const node = tree.find('Link Text')
  expect(node.text()).toBe('1 Sectionsections name')
  const screenReaderNode = tree.find('ScreenReaderContent')
  expect(screenReaderNode.text()).toBe('sections name')
})

test('renders all sections if no sections are given', () => {
  const props = defaultProps()
  props.sections = null
  const tree = mount(<SectionTooltip {...props} />)
  const node = tree.find('Link Text')
  expect(node.text()).toBe('All Sections')
})

test('renders tooltip text correcly with sections', () => {
  const tree = shallow(<SectionTooltip {...defaultProps()} />)
  const node = tree.find('Tooltip')
  expect(mount(node.prop('tip')[0]).find('Container Text').text()).toBe('sections name (4 Users)')
})

test('renders multiple sections into tooltip', () => {
  const props = defaultProps()
  props.sections[1] = {id: 3, name: 'section other name', user_count: 8}
  const tree = shallow(<SectionTooltip {...props} />)
  const node = tree.find('Tooltip')
  expect(node.prop('tip')).toHaveLength(2)
  expect(mount(node.prop('tip')[1]).find('Container Text').text()).toBe('section other name (8 Users)')
})

test('renders tooltip text correcly without', () => {
  const props = defaultProps()
  props.sections = null
  const tree = shallow(<SectionTooltip {...props} />)
  const node = tree.find('Tooltip')
  expect(mount(node.prop('tip')).find('Container Text').text()).toBe('(5 Users)')
})

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
import {render} from '@testing-library/react'
import SectionTooltip from '../index'

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
  const node = tree.find('Text')
  expect(node.first().text()).toBe('1 Sectionsections name')
  const screenReaderNode = tree.find('ScreenReaderContent').first()
  expect(screenReaderNode.text()).toBe('sections name')
})

test('renders prefix text when passed in', () => {
  const props = defaultProps()
  props.prefix = 'Anonymous Discussion | '
  const tree = mount(<SectionTooltip {...props} />)
  const node = tree.find('Text')
  expect(node.first().text()).toBe('Anonymous Discussion | 1 Sectionsections name')
})

test('uses textColor from props', () => {
  const props = defaultProps()
  props.textColor = 'secondary'
  const tree = mount(<SectionTooltip {...props} />)
  const node = tree.find('Text')
  expect(node.first().props().color).toBe('secondary')
})

test('renders all sections if no sections are given', () => {
  const props = defaultProps()
  props.sections = null
  const {getByText} = render(<SectionTooltip {...props} />)

  const allSectionsText = getByText('All Sections')
  expect(allSectionsText).toBeInTheDocument()
})

test('renders tooltip text correcly with sections', () => {
  const tree = shallow(<SectionTooltip {...defaultProps()} />)
  const node = tree.find('Tooltip')
  expect(mount(node.prop('renderTip')[0]).find('View Text').first().text()).toBe(
    'sections name (4 Users)'
  )
})

test('renders multiple sections into tooltip', () => {
  const props = defaultProps()
  props.sections[1] = {id: 3, name: 'section other name', user_count: 8}
  const tree = shallow(<SectionTooltip {...props} />)
  const node = tree.find('Tooltip')
  expect(node.prop('renderTip')).toHaveLength(2)
  expect(mount(node.prop('renderTip')[1]).find('View Text').first().text()).toBe(
    'section other name (8 Users)'
  )
})

test('does not renders tooltip text when All Sections', () => {
  const props = defaultProps()
  props.sections = null
  const tree = shallow(<SectionTooltip {...props} />)
  const node = tree.find('Tooltip')
  expect(node).toEqual({})
})

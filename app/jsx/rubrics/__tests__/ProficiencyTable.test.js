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
import { shallow } from 'enzyme'
import ProficiencyTable from '../ProficiencyTable'

const defaultProps = (props = {}) => (
  Object.assign({
  }, props)
)

it('renders the ProficiencyRating component', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('defaults to four ratings', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  expect(wrapper.find('ProficiencyRating')).toHaveLength(4)
})

it('clicking button adds rating', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  wrapper.find('Button').first().simulate('click')
  expect(wrapper.find('ProficiencyRating')).toHaveLength(5)
})

it('handling delete rating removes rating', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  wrapper.instance().handleDelete(0)()
  expect(wrapper.find('ProficiencyRating')).toHaveLength(3)
})

it('empty rating description leaves state invalid', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  wrapper.instance().handleDescriptionChange(0)("")
  expect(wrapper.instance().isStateValid()).toBe(false)
})

it('empty rating points leaves state invalid', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  wrapper.instance().handlePointsChange(0)("")
  expect(wrapper.instance().isStateValid()).toBe(false)
})

it('invalid rating points leaves state invalid', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  wrapper.instance().handlePointsChange(0)("1.1.1")
  expect(wrapper.instance().isStateValid()).toBe(false)
})

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

/*
  TODO: Duplicated and modified within jsx/outcomes/MasteryScale for use there
        Remove when feature flag account_level_mastery_scales is enabled
*/

import React from 'react'
import {mount, shallow} from 'enzyme'
import ProficiencyRating from '../ProficiencyRating'

const defaultProps = (props = {}) => ({
  color: '00ff00',
  description: 'Stellar',
  disableDelete: false,
  mastery: false,
  onColorChange: () => {},
  onDelete: () => {},
  onDescriptionChange: () => {},
  onMasteryChange: () => {},
  onPointsChange: () => {},
  points: '10.0',
  ...props,
})

it('renders the ProficiencyRating component', () => {
  const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('mastery checkbox is checked if mastery', () => {
  const wrapper = shallow(
    <ProficiencyRating
      {...defaultProps({
        mastery: true,
      })}
    />
  )
  const radio = wrapper.find('RadioInput')
  expect(radio.props().checked).toBe(true)
})

describe('focus handling', () => {
  let containerElement = null
  let wrapper = null

  beforeEach(() => {
    containerElement = document.createElement('div')
    document.body.appendChild(containerElement)
  })

  afterEach(() => {
    if (wrapper) wrapper.unmount()
    document.body.removeChild(containerElement)
  })

  it('mastery checkbox receives focus', () => {
    wrapper = mount(
      <table>
        <tbody>
          <ProficiencyRating {...defaultProps({focusField: 'mastery'})} />
        </tbody>
      </table>,
      {attachTo: containerElement}
    )
    expect(wrapper.find('RadioInput').find('input').instance()).toBe(document.activeElement)
  })
})

it('clicking mastery checkbox triggers change', () => {
  const onMasteryChange = jest.fn()
  const wrapper = mount(
    <table>
      <tbody>
        <ProficiencyRating {...defaultProps({onMasteryChange})} />
      </tbody>
    </table>
  )
  wrapper.find('RadioInput').find('input').simulate('change')
  expect(onMasteryChange).toHaveBeenCalledTimes(1)
})

it('includes the rating description', () => {
  const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
  const input = wrapper.find('TextInput').at(0)
  expect(input.prop('defaultValue')).toBe('Stellar')
})

it('changing description triggers change', () => {
  const onDescriptionChange = jest.fn()
  const wrapper = mount(
    <table>
      <tbody>
        <ProficiencyRating {...defaultProps({onDescriptionChange})} />
      </tbody>
    </table>
  )
  wrapper.find('TextInput').at(0).find('input').simulate('change')
  expect(onDescriptionChange).toHaveBeenCalledTimes(1)
})

it('includes the points', () => {
  const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
  const input = wrapper.find('TextInput').at(1)
  expect(input.prop('defaultValue')).toBe('10')
})

it('changing points triggers change', () => {
  const onPointsChange = jest.fn()
  const wrapper = mount(
    <table>
      <tbody>
        <ProficiencyRating {...defaultProps({onPointsChange})} />
      </tbody>
    </table>
  )
  wrapper.find('TextInput').at(3).find('input').simulate('change')
  expect(onPointsChange).toHaveBeenCalledTimes(1)
})

it('clicking delete button triggers delete', () => {
  const onDelete = jest.fn()
  const wrapper = mount(
    <table>
      <tbody>
        <ProficiencyRating {...defaultProps({onDelete})} />
      </tbody>
    </table>
  )
  wrapper.find('IconButton').at(1).simulate('click')
  expect(onDelete).toHaveBeenCalledTimes(1)
})

it('clicking disabled delete button does not triggers delete', () => {
  const onDelete = jest.fn()
  const wrapper = mount(
    <table>
      <tbody>
        <ProficiencyRating
          {...defaultProps({
            onDelete,
            disableDelete: true,
          })}
        />
      </tbody>
    </table>
  )
  wrapper.find('IconButton').at(1).simulate('click')
  expect(onDelete).toHaveBeenCalledTimes(0)
})

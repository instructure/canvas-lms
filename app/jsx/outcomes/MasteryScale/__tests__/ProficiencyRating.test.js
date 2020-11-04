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
  position: 1,
  ...props
})

describe('ProficiencyRating', () => {
  describe('can not manage', () => {
    it('renders the ProficiencyRating component', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: false})} />)
      expect(wrapper).toMatchSnapshot()
    })

    it('mastery checkbox is checked if mastery', () => {
      const wrapper = shallow(
        <ProficiencyRating
          {...defaultProps({
            mastery: true,
            canManage: false
          })}
        />
      )
      const radio = wrapper.find('RadioInput')
      expect(radio.props().checked).toBe(true)
    })

    it('mastery checkbox does not appear if not mastery', () => {
      const wrapper = shallow(
        <ProficiencyRating
          {...defaultProps({
            mastery: false,
            canManage: false
          })}
        />
      )
      const radio = wrapper.find('RadioInput')
      expect(radio.exists()).toBeFalsy()
    })

    it('mastery checkbox does not receive focus', () => {
      const wrapper = mount(
        <div>
          <ProficiencyRating
            {...defaultProps({focusField: 'mastery', canManage: false, mastery: true})}
          />
        </div>
      )
      expect(
        wrapper
          .find('RadioInput')
          .find('input')
          .instance()
      ).not.toBe(document.activeElement)
    })

    it('clicking mastery checkbox does not trigger change', () => {
      const onMasteryChange = jest.fn()
      const wrapper = mount(
        <ProficiencyRating {...defaultProps({onMasteryChange, mastery: true, canManage: false})} />
      )
      wrapper
        .find('RadioInput')
        .find('input')
        .simulate('change')
      expect(onMasteryChange).not.toHaveBeenCalled()
    })

    it('does not render TextInput', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: false})} />)
      expect(wrapper.find('TextInput').exists()).toBeFalsy()
    })
    it('does not render delete button', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: false})} />)
      expect(wrapper.find('.deleteButton').exists()).toBeFalsy()
    })

    it('includes the points', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: false})} />)
      const content = wrapper
        .find('.points')
        .find('PresentationContent')
        .at(0)
      expect(content.childAt(0).text()).toBe('10')
    })
  })

  describe('can manage', () => {
    it('renders the ProficiencyRating component', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: true})} />)
      expect(wrapper).toMatchSnapshot()
    })

    it('mastery checkbox is checked if mastery', () => {
      const wrapper = shallow(
        <ProficiencyRating
          {...defaultProps({
            mastery: true,
            canManage: true
          })}
        />
      )
      const radio = wrapper.find('RadioInput')
      expect(radio.props().checked).toBe(true)
    })

    it('mastery checkbox receives focus', () => {
      const wrapper = mount(
        <div>
          <ProficiencyRating {...defaultProps({focusField: 'mastery', canManage: true})} />
        </div>
      )
      expect(
        wrapper
          .find('RadioInput')
          .find('input')
          .instance()
      ).toBe(document.activeElement)
    })

    it('clicking mastery checkbox triggers change', () => {
      const onMasteryChange = jest.fn()
      const wrapper = mount(
        <ProficiencyRating {...defaultProps({onMasteryChange, canManage: true})} />
      )
      wrapper
        .find('RadioInput')
        .find('input')
        .simulate('change')
      expect(onMasteryChange).toHaveBeenCalledTimes(1)
    })

    it('includes the rating description', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: true})} />)
      const input = wrapper.find('TextInput').at(0)
      expect(input.prop('defaultValue')).toBe('Stellar')
    })

    it('changing description triggers change', () => {
      const onDescriptionChange = jest.fn()
      const wrapper = mount(
        <ProficiencyRating {...defaultProps({onDescriptionChange, canManage: true})} />
      )
      wrapper
        .find('TextInput')
        .at(0)
        .find('input')
        .simulate('change')
      expect(onDescriptionChange).toHaveBeenCalledTimes(1)
    })

    it('includes the points', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: true})} />)
      const input = wrapper.find('TextInput').at(1)
      expect(input.prop('defaultValue')).toBe('10')
    })

    it('changing points triggers change', () => {
      const onPointsChange = jest.fn()
      const wrapper = mount(
        <ProficiencyRating {...defaultProps({onPointsChange, canManage: true})} />
      )
      wrapper
        .find('TextInput')
        .at(1)
        .find('input')
        .simulate('change')
      expect(onPointsChange).toHaveBeenCalledTimes(1)
    })

    it('clicking delete button triggers delete', () => {
      const onDelete = jest.fn()
      const wrapper = mount(<ProficiencyRating {...defaultProps({onDelete, canManage: true})} />)
      wrapper
        .find('IconButton')
        .at(0)
        .simulate('click')
      expect(onDelete).toHaveBeenCalledTimes(1)
    })

    it('clicking disabled delete button does not triggers delete', () => {
      const onDelete = jest.fn()
      const wrapper = mount(
        <ProficiencyRating
          {...defaultProps({
            onDelete,
            disableDelete: true,
            canManage: true
          })}
        />
      )
      wrapper
        .find('IconButton')
        .at(0)
        .simulate('click')
      expect(onDelete).toHaveBeenCalledTimes(0)
    })
  })
})

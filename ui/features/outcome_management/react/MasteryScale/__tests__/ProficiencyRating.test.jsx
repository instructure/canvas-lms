// @vitest-environment jsdom
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
import {render, fireEvent} from '@testing-library/react'
import ProficiencyRating from '../ProficiencyRating'

describe('ProficiencyRating', () => {
  let onDeleteMock
  let onFocusChangeMock
  let onMasteryChangeMock
  let onDescriptionChangeMock
  let onPointsChangeMock

  const defaultProps = (props = {}) => ({
    color: '00ff00',
    description: 'Stellar',
    disableDelete: false,
    mastery: false,
    canManage: false,
    onColorChange: () => {},
    onDelete: onDeleteMock,
    onDescriptionChange: onDescriptionChangeMock,
    onFocusChange: onFocusChangeMock,
    onMasteryChange: onMasteryChangeMock,
    onPointsChange: onPointsChangeMock,
    points: '10.0',
    position: 1,
    ...props,
  })

  beforeEach(() => {
    onDeleteMock = jest.fn()
    onFocusChangeMock = jest.fn()
    onMasteryChangeMock = jest.fn()
    onDescriptionChangeMock = jest.fn()
    onPointsChangeMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('can not manage', () => {
    it('renders the ProficiencyRating component', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
      expect(wrapper).toMatchSnapshot()
    })

    it('mastery checkbox is checked if mastery', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({mastery: true})} />)
      const radio = wrapper.find('RadioInput')
      expect(radio.props().checked).toBe(true)
    })

    it('mastery checkbox does not appear if not mastery', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
      const radio = wrapper.find('RadioInput')
      expect(radio.exists()).toBeFalsy()
    })

    it('mastery checkbox does not receive focus', () => {
      const wrapper = mount(
        <div>
          <ProficiencyRating {...defaultProps({focusField: 'mastery', mastery: true})} />
        </div>
      )
      expect(wrapper.find('RadioInput').find('input').instance()).not.toBe(document.activeElement)
    })

    it('clicking mastery checkbox does not trigger change', () => {
      const wrapper = mount(<ProficiencyRating {...defaultProps({mastery: true})} />)
      wrapper.find('RadioInput').find('input').simulate('change')
      expect(onMasteryChangeMock).not.toHaveBeenCalled()
    })

    it('does not render TextInput', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
      expect(wrapper.find('TextInput').exists()).toBeFalsy()
    })

    it('does not render delete button', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
      expect(wrapper.find('.deleteButton').exists()).toBeFalsy()
    })

    it('includes the points', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
      const content = wrapper.find('.points').find('PresentationContent').at(0)
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
            canManage: true,
          })}
        />
      )
      const radio = wrapper.find('RadioInput')
      expect(radio.props().checked).toBe(true)
    })

    it('clicking mastery checkbox triggers change', () => {
      const wrapper = mount(<ProficiencyRating {...defaultProps({canManage: true})} />)
      wrapper.find('RadioInput').find('input').simulate('change')
      expect(onMasteryChangeMock).toHaveBeenCalledTimes(1)
    })

    it('includes the rating description', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: true})} />)
      const input = wrapper.find('TextInput').at(0)
      expect(input.prop('defaultValue')).toBe('Stellar')
    })

    it('changing description triggers change', () => {
      const wrapper = mount(<ProficiencyRating {...defaultProps({canManage: true})} />)
      wrapper.find('TextInput').at(0).find('input').simulate('change')
      expect(onDescriptionChangeMock).toHaveBeenCalledTimes(1)
    })

    it('includes the points', () => {
      const wrapper = shallow(<ProficiencyRating {...defaultProps({canManage: true})} />)
      const input = wrapper.find('TextInput').at(1)
      expect(input.prop('defaultValue')).toBe('10')
    })

    it('changing points triggers change', () => {
      const {getAllByRole} = render(<ProficiencyRating {...defaultProps({canManage: true})} />)
      const secondInput = getAllByRole('textbox')[1]
      fireEvent.change(secondInput, {target: {value: 'some new value'}})

      expect(onPointsChangeMock).toHaveBeenCalledTimes(1)
    })

    it('calls onDelete prop when click on delete and confirm in the confirmation modal', () => {
      const {getByText} = render(<ProficiencyRating {...defaultProps({canManage: true})} />)
      fireEvent.click(getByText('Delete mastery level 1'))
      fireEvent.click(getByText('Confirm'))
      expect(onDeleteMock).toHaveBeenCalledTimes(1)
    })

    it('clicking disabled delete button does not show delete modal', () => {
      const {queryByText} = render(
        <ProficiencyRating
          {...defaultProps({
            disableDelete: true,
            canManage: true,
          })}
        />
      )
      fireEvent.click(queryByText('Delete mastery level 1'))
      expect(queryByText('Remove Mastery Level')).not.toBeInTheDocument()
    })

    it('shows color input', () => {
      const {getByText} = render(<ProficiencyRating {...defaultProps({canManage: true})} />)
      expect(getByText('Change color for mastery level 1')).toBeInTheDocument()
    })

    it('calls onFocusChange prop when current input looses focus', () => {
      const wrapper = mount(<ProficiencyRating {...defaultProps({canManage: true})} />)
      wrapper.find('TextInput').at(0).find('input').simulate('blur')
      wrapper.find('TextInput').at(1).find('input').simulate('blur')
      expect(onFocusChangeMock).toHaveBeenCalledTimes(2)
    })

    describe('when individualOutcome is true', () => {
      it('hides color input', () => {
        const {queryByText, container} = render(
          <ProficiencyRating {...defaultProps({canManage: true, individualOutcome: true})} />
        )
        expect(queryByText('Change color for mastery level 1')).not.toBeInTheDocument()
        expect(container.getElementsByClassName('color').length).toBe(0)
      })
    })
  })
})

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
import axios from 'axios'
import { mount, shallow } from 'enzyme'
import ProficiencyTable from '../ProficiencyTable'

const defaultProps = (props = {}) => (
  Object.assign({
    accountId: '1'
  }, props)
)

let promise
let getSpy

describe('default proficiency', () => {
  beforeEach(() => {
    promise = Promise.resolve({status: 404})
    getSpy = jest.spyOn(axios,'get').mockImplementation(() => promise)
  })

  afterEach(() => {
    getSpy.mockRestore()
  })

  it('renders the ProficiencyRating component', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
    expect(wrapper.debug()).toMatchSnapshot()
  })

  it('renders loading at startup', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
    expect(wrapper.find('Spinner')).toHaveLength(1)
  })

  it('renders four ratings', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() =>
      expect(wrapper.find('ProficiencyRating')).toHaveLength(4)
    )
  })

  it('clicking button adds rating', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.findWhere(n => n.prop('variant') === 'circle-primary').simulate('click')
      expect(wrapper.find('ProficiencyRating')).toHaveLength(5)
    })
  })

  it('handling delete rating removes rating', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.instance().handleDelete(0)()
      expect(wrapper.find('ProficiencyRating')).toHaveLength(3)
    })
  })

  it('setting blank description sets error', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.instance().handleDescriptionChange(0)("")
      wrapper.find('Button').last().simulate('click')
      expect(wrapper.find('ProficiencyRating').first().prop('descriptionError')).toBe('Missing required description')
    })
  })

  it('setting blank points sets error', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.instance().handlePointsChange(0)("")
      wrapper.find('Button').last().simulate('click')
      expect(wrapper.find('ProficiencyRating').first().prop('pointsError')).toBe('Invalid points')
    })
  })

  it('setting invalid points sets error', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.instance().handlePointsChange(0)("1.1.1")
      wrapper.find('Button').last().simulate('click')
      expect(wrapper.find('ProficiencyRating').first().prop('pointsError')).toBe('Invalid points')
    })
  })

  it('setting negative points sets error', () => {
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.instance().handlePointsChange(0)("-1")
      wrapper.find('Button').last().simulate('click')
      expect(wrapper.find('ProficiencyRating').first().prop('pointsError')).toBe('Negative points')
    })
  })

  it('sends POST on submit', () => {
    const postSpy = jest.spyOn(axios,'post').mockImplementation(() => Promise.resolve({status: 200}))
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
      wrapper.find('Button').last().simulate('click')
      expect(axios.post).toHaveBeenCalledTimes(1)
      postSpy.mockRestore()
    })
  })
})

describe('custom proficiency', () => {
  it('renders two ratings that are deletable', () => {
    promise = Promise.resolve({
      status: 200,
      data: {ratings: [
        {
          description: 'Great',
          points: 10,
          color: '0000ff',
          mastery: true
        },
        {
          description: 'Poor',
          points: 0,
          color: 'ff0000',
          mastery: false
        }
      ]}
    })
    const spy = jest.spyOn(axios,'get').mockImplementation(() => promise)
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
        spy.mockRestore()
        expect(wrapper.find('ProficiencyRating')).toHaveLength(2)
        expect(wrapper.find('ProficiencyRating').first().prop('disableDelete')).toBeFalsy()
        expect(wrapper.find('ProficiencyRating').last().prop('disableDelete')).toBeFalsy()
      }
    )
  })

  it('renders one rating that is not deletable', () => {
    promise = Promise.resolve({
      status: 200,
      data: {ratings: [
        {
          description: 'Uno',
          points: 1,
          color: '0000ff',
          mastery: true
        }
      ]}
    })
    const spy = jest.spyOn(axios,'get').mockImplementation(() => promise)
    const wrapper = mount(<ProficiencyTable {...defaultProps()}/>)
    return promise.then(() => {
        spy.mockRestore()
        expect(wrapper.find('ProficiencyRating')).toHaveLength(1)
        expect(wrapper.find('ProficiencyRating').first().prop('disableDelete')).toBeTruthy()
      }
    )
  })
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

it('negative rating points leaves state invalid', () => {
  const wrapper = shallow(<ProficiencyTable {...defaultProps()}/>)
  wrapper.instance().handlePointsChange(0)("-1")
  expect(wrapper.instance().isStateValid()).toBe(false)
})

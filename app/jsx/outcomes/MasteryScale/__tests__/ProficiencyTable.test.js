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
import $ from 'jquery'
import React from 'react'
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
import ProficiencyTable from '../ProficiencyTable'

const defaultProps = {
  update: Function.prototype
}

describe('default proficiency', () => {
  it('renders the ProficiencyRating component', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps} />)
    expect(getByText('Proficiency Rating')).not.toBeNull()
  })

  it('renders five ratings', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      expect(wrapper.find('ProficiencyRating')).toHaveLength(5)
      done()
    }, 1)
  })

  it('sets focusField on mastery on first rating only', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      expect(
        wrapper
          .find('ProficiencyRating')
          .at(0)
          .prop('focusField')
      ).toBe('mastery')
      expect(
        wrapper
          .find('ProficiencyRating')
          .at(1)
          .prop('focusField')
      ).toBeNull()
      expect(
        wrapper
          .find('ProficiencyRating')
          .at(2)
          .prop('focusField')
      ).toBeNull()
      expect(
        wrapper
          .find('ProficiencyRating')
          .at(3)
          .prop('focusField')
      ).toBeNull()
      expect(
        wrapper
          .find('ProficiencyRating')
          .at(4)
          .prop('focusField')
      ).toBeNull()
      done()
    }, 1)
  })

  it('clicking button adds rating', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      wrapper.findWhere(n => n.prop('variant') === 'circle-primary').simulate('click')
      expect(wrapper.find('ProficiencyRating')).toHaveLength(6)
      done()
    }, 1)
  })

  it('clicking add rating button flashes SR message', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')
    setTimeout(() => {
      wrapper.findWhere(n => n.prop('variant') === 'circle-primary').simulate('click')
      expect(flashMock).toHaveBeenCalledTimes(1)
      flashMock.mockRestore()
      done()
    }, 1)
  })

  it('handling delete rating removes rating and flashes SR message', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')
    setTimeout(() => {
      wrapper.instance().handleDelete(1)()
      expect(wrapper.find('ProficiencyRating')).toHaveLength(4)
      expect(flashMock).toHaveBeenCalledTimes(1)
      flashMock.mockRestore()
      done()
    }, 1)
  })

  it('setting blank description sets error', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      wrapper.instance().handleDescriptionChange(0)('')
      wrapper
        .find('Button')
        .last()
        .simulate('click')
      expect(
        wrapper
          .find('ProficiencyRating')
          .first()
          .prop('descriptionError')
      ).toBe('Missing required description')
      done()
    }, 1)
  })

  it('setting blank points sets error', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      wrapper.instance().handlePointsChange(0)('')
      wrapper
        .find('Button')
        .last()
        .simulate('click')
      expect(
        wrapper
          .find('ProficiencyRating')
          .first()
          .prop('pointsError')
      ).toBe('Invalid points')
      done()
    }, 1)
  })

  it('setting invalid points sets error', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      wrapper.instance().handlePointsChange(0)('1.1.1')
      wrapper
        .find('Button')
        .last()
        .simulate('click')
      expect(
        wrapper
          .find('ProficiencyRating')
          .first()
          .prop('pointsError')
      ).toBe('Invalid points')
      done()
    }, 1)
  })

  it('setting negative points sets error', done => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    setTimeout(() => {
      wrapper.instance().handlePointsChange(0)('-1')
      wrapper
        .find('Button')
        .last()
        .simulate('click')
      expect(
        wrapper
          .find('ProficiencyRating')
          .first()
          .prop('pointsError')
      ).toBe('Negative points')
      done()
    }, 1)
  })

  it('calls update on submit', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const wrapper = shallow(<ProficiencyTable {...defaultProps} update={updateSpy} />)
    wrapper
      .find('Button')
      .last()
      .simulate('click')
    expect(updateSpy).toHaveBeenCalledTimes(1)
  })

  it('empty rating description generates errors', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    wrapper.instance().handleDescriptionChange(0)('')
    expect(wrapper.instance().checkForErrors()).toBe(true)
  })

  it('empty rating points generates errors', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    wrapper.instance().handlePointsChange(0)('')
    expect(wrapper.instance().checkForErrors()).toBe(true)
  })

  it('invalid rating points generates errors', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    wrapper.instance().handlePointsChange(0)('1.1.1')
    expect(wrapper.instance().checkForErrors()).toBe(true)
  })

  it('increasing rating points generates errors', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    wrapper.instance().handlePointsChange(1)('100')
    expect(wrapper.instance().checkForErrors()).toBe(true)
  })

  it('negative rating points leaves state invalid', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    wrapper.instance().handlePointsChange(0)('-1')
    expect(wrapper.instance().isStateValid()).toBe(false)
  })
})

describe('custom proficiency', () => {
  const customProficiencyProps = {
    ...defaultProps,
    proficiency: {
      proficiencyRatingsConnection: {
        nodes: [
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
        ]
      }
    }
  }

  it('renders two ratings that are deletable', () => {
    const wrapper = shallow(<ProficiencyTable {...customProficiencyProps} />)
    expect(wrapper.find('ProficiencyRating')).toHaveLength(2)
    expect(
      wrapper
        .find('ProficiencyRating')
        .first()
        .prop('disableDelete')
    ).toBeFalsy()
    expect(
      wrapper
        .find('ProficiencyRating')
        .last()
        .prop('disableDelete')
    ).toBeFalsy()
  })

  it('renders one rating that is not deletable', () => {
    const props = {
      ...defaultProps,
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [
            {
              description: 'Uno',
              points: 1,
              color: '0000ff',
              mastery: true
            }
          ]
        }
      }
    }
    const wrapper = shallow(<ProficiencyTable {...props} />)
    expect(wrapper.find('ProficiencyRating')).toHaveLength(1)
    expect(
      wrapper
        .find('ProficiencyRating')
        .first()
        .prop('disableDelete')
    ).toBeTruthy()
  })
})

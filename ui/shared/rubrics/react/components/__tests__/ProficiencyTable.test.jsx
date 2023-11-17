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

import _ from 'lodash'
import $ from 'jquery'
import React from 'react'
import axios from '@canvas/axios'
import {shallow} from 'enzyme'
import {waitFor} from '@testing-library/react'
import ProficiencyTable from '../ProficiencyTable'

function wait(ms = 0) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

const defaultProps = {
  accountId: '1',
}

// Because we had to override the displayName of the <ProficiencyRating> component in
// order to make InstUI's prop checking happy, finding them is a bit more involved.
function findProficiencyRatings(shallowWrapper) {
  return shallowWrapper.find('Row').filterWhere(c => c.type().name === 'ProficiencyRating')
}

let getSpy

describe('default proficiency', () => {
  beforeEach(() => {
    const err = _.assign(new Error(), {response: {status: 404}})
    getSpy = jest.spyOn(axios, 'get').mockImplementation(() => Promise.reject(err))
  })

  afterEach(() => {
    getSpy.mockRestore()
  })

  it('renders the ProficiencyRating component', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    expect(wrapper).toMatchSnapshot()
  })

  it('renders loading at startup', () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    expect(wrapper.find('Spinner')).toHaveLength(1)
  })

  it('render billboard after loading', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    await waitFor(() => {
      expect(wrapper.find('Billboard')).toHaveLength(1)
    })
  })
  it('renders five ratings', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    wrapper.instance().removeBillboard()
    expect(findProficiencyRatings(wrapper)).toHaveLength(5)
  })

  it('sets focusField on mastery on first rating only', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    wrapper.instance().removeBillboard()
    const ratings = findProficiencyRatings(wrapper)
    expect(ratings.at(0).prop('focusField')).toBe('mastery')
    expect(ratings.at(1).prop('focusField')).toBeNull()
    expect(ratings.at(2).prop('focusField')).toBeNull()
    expect(ratings.at(3).prop('focusField')).toBeNull()
    expect(ratings.at(4).prop('focusField')).toBeNull()
  })

  it('clicking button adds rating', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.findWhere(n => n.prop('shape') === 'circle').simulate('click')
    expect(findProficiencyRatings(wrapper)).toHaveLength(6)
  })

  it('clicking add rating button flashes SR message', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')

    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.findWhere(n => n.prop('shape') === 'circle').simulate('click')
    expect(flashMock).toHaveBeenCalledTimes(1)
    flashMock.mockRestore()
  })

  it('handling delete rating removes rating and flashes SR message', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')

    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.instance().handleDelete(1)()
    expect(findProficiencyRatings(wrapper)).toHaveLength(4)
    expect(flashMock).toHaveBeenCalledTimes(1)
    flashMock.mockRestore()
  })

  it('setting blank description sets error', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.instance().handleDescriptionChange(0)('')
    wrapper.find('Button').last().simulate('click')
    expect(findProficiencyRatings(wrapper).first().prop('descriptionError')).toBe(
      'Missing required description'
    )
  })

  it('setting blank points sets error', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.instance().handlePointsChange(0)('')
    wrapper.find('Button').last().simulate('click')
    expect(findProficiencyRatings(wrapper).first().prop('pointsError')).toBe('Invalid points')
  })

  it('setting invalid points sets error', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.instance().handlePointsChange(0)('1.1.1')
    wrapper.find('Button').last().simulate('click')
    expect(findProficiencyRatings(wrapper).first().prop('pointsError')).toBe('Invalid points')
  })

  it('setting negative points sets error', async () => {
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    // Wait for 1 ms (or however long needed for your async operations)
    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.instance().handlePointsChange(0)('-1')
    wrapper.find('Button').last().simulate('click')
    expect(findProficiencyRatings(wrapper).first().prop('pointsError')).toBe('Negative points')
  })

  it('sends POST on submit', async () => {
    const postSpy = jest
      .spyOn(axios, 'post')
      .mockImplementation(() => Promise.resolve({status: 200}))

    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)

    // Wait for 1 ms (or however long needed for your async operations)
    await wait(1)

    wrapper.instance().removeBillboard()
    wrapper.find('Button').last().simulate('click')

    // Ensure that the mocked POST request was called
    expect(axios.post).toHaveBeenCalledTimes(1)

    postSpy.mockRestore()
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
  it('renders two ratings that are deletable', () => {
    const promise = Promise.resolve({
      status: 200,
      data: {
        ratings: [
          {
            description: 'Great',
            points: 10,
            color: '0000ff',
            mastery: true,
          },
          {
            description: 'Poor',
            points: 0,
            color: 'ff0000',
            mastery: false,
          },
        ],
      },
    })
    const spy = jest.spyOn(axios, 'get').mockImplementation(() => promise)
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    return promise.then(() => {
      spy.mockRestore()
      const ratings = findProficiencyRatings(wrapper)
      expect(ratings).toHaveLength(2)
      ratings.forEach(r => {
        expect(r.prop('disableDelete')).toBeFalsy()
      })
    })
  })

  it('renders one rating that is not deletable', () => {
    const promise = Promise.resolve({
      status: 200,
      data: {
        ratings: [
          {
            description: 'Uno',
            points: 1,
            color: '0000ff',
            mastery: true,
          },
        ],
      },
    })
    const spy = jest.spyOn(axios, 'get').mockImplementation(() => promise)
    const wrapper = shallow(<ProficiencyTable {...defaultProps} />)
    return promise.then(() => {
      spy.mockRestore()
      const ratings = findProficiencyRatings(wrapper)
      expect(ratings).toHaveLength(1)
      ratings.forEach(r => {
        expect(r.prop('disableDelete')).toBeTruthy()
      })
    })
  })
})

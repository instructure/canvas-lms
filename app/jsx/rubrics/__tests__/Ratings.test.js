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
import sinon from 'sinon'
import Ratings, { Rating } from '../Ratings'

describe('The Ratings component', () => {
  const props = {
    assessing: false,
    tiers: [
      { description: 'Superb', points: 10 },
      { description: 'Meh', long_description: 'More Verbosity', points: 5 },
      { description: 'Subpar', points: 1 }
    ],
    points: 5,
    defaultMasteryThreshold: 10,
    useRange: false
  }

  const component = (mods) => shallow(<Ratings {...{ ...props, ...mods }} />)
  it('renders the root component as expected', () => {
    expect(component().debug()).toMatchSnapshot()
  })

  it('renders the Rating sub-components as expected when range rating enabled', () => {
    const useRange = true
    component({ useRange }).find('Rating')
      .forEach((el) => expect(el.shallow().debug()).toMatchSnapshot())
  })

  it('highlights the right rating', () => {
    const ratings = (points, useRange = false) =>
      component({ points, useRange }).find('Rating').map((el) => el.shallow().hasClass('selected'))

    expect(ratings(10)).toEqual([true, false, false])
    expect(ratings(8)).toEqual([false, false, false])
    expect(ratings(8, true)).toEqual([true, false, false])
    expect(ratings(5)).toEqual([false, true, false])
    expect(ratings(3)).toEqual([false, false, false])
    expect(ratings(3, true)).toEqual([false, true, false])
    expect(ratings(1)).toEqual([false, false, true])
    expect(ratings(0, true)).toEqual([false, false, true])
    expect(ratings(undefined)).toEqual([false, false, false])
  })

  it('calls onPointChange when a rating is clicked', () => {
    const onPointChange = sinon.spy()
    const el = component({ onPointChange })

    el.find('Rating').first().prop('onClick').call()
    expect(onPointChange.args[0]).toEqual([10])
  })

  it('uses the right default mastery level colors', () => {
    const mastery = (points) =>
      component({ points }).find('Rating').map((el) => el.prop('tierColor'))
    expect(mastery(10)).toEqual(["#8aac53", 'transparent', 'transparent'])
    expect(mastery(5)).toEqual(['transparent', "#e0d773", 'transparent'])
    expect(mastery(1)).toEqual(['transparent', 'transparent', "#df5b59"])
  })

  it('uses the right custom rating colors', () => {
    const customRatings = [
      {points: 10, color: "09BCD3"},
      {points: 5, color: "65499D"},
      {points: 1, color: "F8971C"}
    ]
    const ratings = (points, useRange = false) =>
      component({points, useRange, customRatings}).find('Rating').map((el) => el.prop('tierColor'))
    expect(ratings(10)).toEqual(['#09BCD3', 'transparent', 'transparent'])
    expect(ratings(5)).toEqual(['transparent', '#65499D', 'transparent'])
    expect(ratings(1)).toEqual(['transparent', 'transparent', '#F8971C'])
    expect(ratings(0, true)).toEqual(['transparent', 'transparent', '#F8971C'])
  })

  describe('Rating component', () => {
    it('is navigable and clickable when assessing', () => {
      const onClick = sinon.spy()
      const wrapper = shallow(<Rating {...props.tiers[0]} assessing onClick={onClick} />)
      const div = wrapper.find('div').at(0)
      expect(div.prop('tabIndex')).toEqual(0)
      div.simulate('click')
      expect(onClick.called).toBe(true)
    })

    it('is not navigable or clickable when not assessing', () => {
      const onClick = sinon.spy()
      const wrapper = shallow(<Rating {...props.tiers[0]} assessing={false} onClick={onClick} />)
      const div = wrapper.find('div').at(0)
      expect(div.prop('tabIndex')).toBeNull()
      div.simulate('click')
      expect(onClick.called).toBe(false)
    })
  })
})

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
import $ from 'jquery'
import { shallow } from 'enzyme'
import sinon from 'sinon'
import Ratings, { Rating } from '../Ratings'

// This is needed for $.screenReaderFlashMessageExclusive to work.
import 'compiled/jquery.rails_flash_notifications' // eslint-disable-line

describe('The Ratings component', () => {
  const props = {
    assessing: false,
    footer: null,
    tiers: [
      { description: 'Superb', points: 10 },
      { description: 'Meh', long_description: 'More Verbosity', points: 5 },
      { description: 'Subpar', points: 1 }
    ],
    defaultMasteryThreshold: 10,
    points: 5,
    pointsPossible: 10,
    isSummary: false,
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

  it('calls onPointChange and flashes VO message when a rating is clicked', () => {
    const onPointChange = sinon.spy()
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')
    const el = component({ onPointChange })

    el.find('Rating').first().prop('onClick').call()
    expect(onPointChange.args[0]).toEqual([10])
    expect(flashMock).toHaveBeenCalledTimes(1)
    flashMock.mockRestore()
  })

  it('uses the right default mastery level colors', () => {
    const mastery = (points) =>
      component({ points }).find('Rating').map((el) => el.prop('tierColor'))
    expect(mastery(10)).toEqual([null, 'transparent', 'transparent'])
    expect(mastery(5)).toEqual(['transparent', null, 'transparent'])
    expect(mastery(1)).toEqual(['transparent', 'transparent', null])
    const shaderClasses = (points) =>
      component({ points }).find('Rating').map((el) => el.prop('shaderClass'))
    expect(shaderClasses(10)).toEqual(['meetsMasteryShader', null, null])
    expect(shaderClasses(5)).toEqual([null, 'nearMasteryShader', null])
    expect(shaderClasses(1)).toEqual([null, null, 'wellBelowMasteryShader'])
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

  describe('custom ratings', () => {
    const customRatings = [
      {points: 100, color: "100100"},
      {points: 60, color: "606060"},
      {points: 10, color: "101010"},
      {points: 1, color: "111111"}
    ]
    const ratings = (points, pointsPossible = 10) =>
      component({ points, pointsPossible, customRatings, useRange: true }).find('Rating').map((el) => el.prop('tierColor'))

    it('scales points to custom ratings', () => {
      expect(ratings(10)).toEqual(['#100100', 'transparent', 'transparent'])
      expect(ratings(6)).toEqual(['#606060', 'transparent', 'transparent'])
      expect(ratings(5)).toEqual(['transparent', '#101010', 'transparent'])
      expect(ratings(4.4)).toEqual(['transparent', '#101010', 'transparent'])
      expect(ratings(1)).toEqual(['transparent', 'transparent', '#101010'])
      expect(ratings(0.1)).toEqual(['transparent', 'transparent', '#111111'])
      expect(ratings(0)).toEqual(['transparent', 'transparent', '#111111'])
    })

    it('does not scale points if pointsPossible is 0', () => {
      expect(ratings(10, 0)).toEqual(['#101010', 'transparent', 'transparent'])
      expect(ratings(4, 0)).toEqual(['transparent', '#111111', 'transparent'])
    })
  })


  const ratingComponent = (overrides) => (
    // eslint-disable-next-line react/prop-types
    <Rating {...props.tiers[0]} isSummary={false} assessing {...overrides} />
  )

  it('is navigable and clickable when assessing', () => {
    const onClick = sinon.spy()
    const wrapper = shallow(ratingComponent({ onClick }))
    const div = wrapper.find('div').at(0)
    expect(div.prop('tabIndex')).toEqual(0)
    div.simulate('click')
    expect(onClick.called).toBe(true)
  })

  it('is not navigable or clickable when not assessing', () => {
    const onClick = sinon.spy()
    const wrapper = shallow(ratingComponent({ assessing: false, onClick }))
    const div = wrapper.find('div').at(0)
    expect(div.prop('tabIndex')).toBeNull()
    expect(div.prop('role')).toBeNull()
    div.simulate('click')
    expect(onClick.called).toBe(false)
  })

  it('only renders the single selected Rating with a footer in summary mode', () => {
    const el = component({ points: 5, isSummary: true, footer: <div>ow my foot</div> })
    const ratings = el.find('Rating')

    expect(ratings).toHaveLength(1)

    const rating = ratings.at(0)
    expect(rating.shallow().debug()).toMatchSnapshot()
  })

  it('renders a default rating if none of the ratings are selected', () => {
    const el = component({ points: 6, isSummary: true, footer: <div>ow my foot</div> })
    const ratings = el.find('Rating')

    expect(ratings).toHaveLength(1)

    const rating = ratings.at(0)
    expect(rating.shallow().debug()).toMatchSnapshot()
  })

  it('hides points on the default rating if points are hidden', () => {
    const el = component({ points: 6, isSummary: true, footer: <div>ow my foot</div> })
    const rating = el.find('Rating')
    expect(rating.prop('hidePoints')).toBe(true)
  })
})

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
import Ratings from '../Ratings'

describe('The Ratings component', () => {
  const props = {
    tiers: [
      { description: 'Superb', points: 10 },
      { description: 'Meh', long_description: 'More Verbosity', points: 5 },
      { description: 'Subpar', points: 2 }
    ],
    points: 4,
    masteryThreshold: 10
  }

  const component = (mods) => shallow(<Ratings {...{ ...props, ...mods }} />)
  it('renders the root component as expected', () => {
    expect(component().debug()).toMatchSnapshot()
  })

  it('highlights the right rating', () => {
    const ratings = (points) =>
      component({ points }).find('Rating').map((el) => el.shallow().hasClass('selected'))

    expect(ratings(9)).toEqual([true, false, false])
    expect(ratings(5)).toEqual([false, true, false])
    expect(ratings(1)).toEqual([false, false, true])
  })

  it('calls onPointChange when a rating is clicked', () => {
    const onPointChange = sinon.spy()
    const el = component({ onPointChange })

    el.find('Rating').first().prop('onClick').call()
    expect(onPointChange.args[0]).toEqual([10])
  })

  it('uses the right mastery level', () => {
    const mastery = (points, mastery_level) =>
      component({ points }).find('Rating').map((el) => el.shallow().hasClass(mastery_level))
    expect(mastery(10, 'full')).toEqual([true, false, false])
    expect(mastery(5, 'partial')).toEqual([false, true, false])
    expect(mastery(1, 'none')).toEqual([false, false, true])
  })
})

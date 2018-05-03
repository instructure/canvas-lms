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
import Ratings from '../Ratings'

describe('The Ratings component', () => {
  const props = {
    tiers: [
      { description: 'Superb', points: 10 },
      { description: 'Meh', long_description: 'More Verbosity', points: 5 },
      { description: 'Subpar', points: 2 }
    ],
    points: 4
  }

  const component = (mods) => shallow(<Ratings {...{ ...props, ...mods }} />)
  it('renders the root component as expected', () => {
    expect(component().debug()).toMatchSnapshot()
  })

  it('renders the Rating sub-components as expected', () => {
    component().find('Rating')
      .forEach((el) => expect(el.shallow().debug()).toMatchSnapshot())
  })

  it('highlights the right rating', () => {
    const ratings = (points) =>
      component({ points }).find('Rating').map((el) => el.prop('selected'))

    expect(ratings(9)).toEqual([true, false, false])
    expect(ratings(5)).toEqual([false, true, false])
    expect(ratings(1)).toEqual([false, false, true])
  })
})

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import CurrentTrophies from '../index'
import React from 'react'

const trophies = [
  {
    trophy_key: 'Foo',
    name: 'Foo',
    description: 'Foo',
    unlocked_at: '2020-06-22T22:42:00+00:00'
  },
  {
    trophy_key: 'Bar',
    name: 'Bar',
    description: 'Bar',
    unlocked_at: null
  }
]

describe('TrophyCase::current', () => {
  it('renders a row for each trophy', () => {
    const {queryAllByAltText} = render(<CurrentTrophies trophies={trophies} />)
    expect(queryAllByAltText(/.*/)).toHaveLength(trophies.length)
  })
})
